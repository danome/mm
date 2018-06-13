#!/usr/bin/env python
import os
import re
import shutil

'''
This script transforms the output from the Silicon Labs Wireless
Development Suite (WDS) Program into code and data that can be used by
our application. The WDS Program can export the source tree for the
configuration settings.

Since each of the WDS source trees is typically 17 megabytes of code,
we don't check all of this in. Instead, we extract the specific text
needed (config info and optional patch), transform it into c-code files
that can be compiled into our application.

Also note that since the WDS program is Microsoft Windows based, we
have to deal with some anomolies. The difference between DOS End of
line is corrected to conform with Linux. The backslash used in the
#include filename needs to be replaced with forward slash before the
link can be followed.

This program expects the following directory structure

-root
   |
   +--- WDS_files  (WDS output files) (*wds_prep.py runs from here)
   |
   |--- mm/tos/chips/si446x/WDS-files   (copies)
   |
   +--- TagNet/si446x/si446x/radioconfig/WDS-files (copies)


For all configuration source trees found in the WDS-files directory
c-code files are generated that contain the information required
by our application. The #include statement is replaced with the
contents of the referenced file.

The collection of output files represent one or more
WDS-generated configurations as well as a selector function for
choosing at runtime the configuration to use from the set compiled in.

The input files to this program come from the WDS Program. The source
tree generated by WDS program contains:
 - <WDS>/src/application/radio_config.h,          WDS config strings
 - <WDS>/src/drivers/radio/Si446x/si446x_patch.h, optional patch strings

The files output from this program include:
 - for each source tree directory found in 'WDS-files'
   - ./<WDS>.c,   API to access specified source tree config into
   - ./<WDS>.h,   config info from source tree in condensed form,
                  includes radio_config.h and si446x_patch.h.
 - the wds_configs.c file provides a single a function to select
   one config from the set included.

wds_radio_configs is a list of tuples representing each of the
configuration source trees. Each tuple consists of the byte
array contains the configuration pstrings and a byte array for
the name of the configuration (actually a null terminated string).
'''

DEFAULT_CONFIG_FILE =  'Si4468_10kb_433m_200khz_psm'


# code to instantiate one configuration from the list
#
# SPECIAL_NAME   is replaced with the name of the configuration (the
#                sub-directory name)
#
# instantiates two variables from selected configuration info:
# - config_name
# - config_pstrings
#
#
config_code = '''
uint8_t const SPECIAL_NAME_config[] = SPECIAL_NAME_DATA_ARRAY;
uint8_t const SPECIAL_NAME_name[] = SPECIAL_NAME_NAME;
wds_config_ids_t const SPECIAL_NAME_ids = SPECIAL_NAME_IDS;
'''

# code used to select one configuration from the compiled list
#
# returns the function that can be called to get the configuration
# information
#
select_code = '''
/* the default configuration is the first in the list. Setting
 * the override will select a different configuration for
 * the default. Needs to be a valid index into wds_radio_configs[]
 */
int wds_default_override  = 0;

int s_compare(uint8_t *s1, uint8_t *s2) {
    while ((*s1) && (*s2) && (*s1 != *s2)) {
        s1++;
        s2++;
    }
    if ((*s1) || (*s2))
        return 0;
    return 1;
}

int wds_set_default(int choice) {
    /* for each config, there are three ptrs in array (3), four bytes
     * per pointer (4), zero indexed (-1), and the last entry is null
     * to mark end-of-list (-1)
     */
    int max_choice = (sizeof(wds_radio_configs) / (3 * 4)) - 2;
    if (choice > max_choice)
        choice = max_choice;
    else if (choice < 0)
        choice = wds_default_override / 3;
    wds_default_override = choice * 3;
    return choice;
}

const uint8_t const * const *wds_config_list() {
    return wds_radio_configs;
}

const uint8_t const *wds_default_name() {
    return wds_radio_configs[wds_default_override+1];
}

const uint8_t const *wds_default_config() {
    return wds_radio_configs[wds_default_override];
}

const wds_config_ids_t *wds_default_ids() {
    return (wds_config_ids_t *) wds_radio_configs[wds_default_override+2];
}

uint8_t const *wds_config_select(uint8_t *cname) {
    uint8_t *this = (void *) wds_radio_configs;
    uint8_t *pname;

    // defaulit is first in list
    if (!cname)
        return wds_radio_configs[wds_default_override];

    while (this) {
        pname = this + 1;
        if (s_compare(cname, pname))
            return this;
        this += 3;
    }
    return NULL;
}
'''
extern_code = '''
int wds_set_default(int level);
uint8_t const* const* wds_config_list();
uint8_t const*              wds_config_select(uint8_t *cname);
uint8_t const*        wds_default_name();
wds_config_ids_t const* wds_default_ids();
'''

typedef_code = '''
typedef struct {
    uint32_t        sig;
    uint32_t        xtal_freq;
    uint32_t        symb_sec;
    uint32_t        freq_dev;
    uint32_t        fhst;
    uint32_t        rxbw;
} wds_config_ids_t;

'''


# each generated file contains this at the beginning
#
comment_code = '''
/*
 * code auto-generated by wds_prep.py
*/

'''


def process_include_file(root, line, output):
    '''
    process data from include file to the output, including:
    extract the filename between the double_quotes, replace
    DOS end of lines with Unix, and write contents of include
    file to the output.

    return true if the include file was copied, else false
    '''
    results = re.findall(r'("([^"]|"")*")',line) # match quotes
    if results:
        # extract include filename from results, strip quotes
        # on the ends, and replace backslashes.
        fname = results[0][0][1:-1].replace('\\','/')
        # strip quotes
        with open(os.path.join(root, fname),'r') as ifd:
            for il in ifd:
                il = il.strip() + '\n'           # remove DOS eol
                output.write(il)
            return True
    return False

def process_config_file(basename, configfile, output):
    '''
    read the input config file and for each line convert from DOS
    to Linux format and look for #include files

    returns a dictionary of configration identifiers found in file
    '''
    pattern= r"(\S+):\s+(\S+)"
    acdc = {}
    with open(configfile,'r') as cfd:
        for cl in cfd:
            cl = cl.strip() + '\n'               # remove DOS eol
            if cl.startswith('#include '):
                if process_include_file(os.path.dirname(configfile),
                                        cl, output):
                    continue # don't write this line if processed
            elif cl.find('RADIO_CONFIGURATION_DATA_ARRAY') >= 0:
                ids = '5883792'
                for id in ['Crys_freq(Hz)', 'Rsymb(sps)', 'Fdev(Hz)', 'fhst', 'RXBW(Hz)']:
                    ids += ', ' + acdc[id]
                output.write('#define ' + basename.upper() + '_IDS {' + ids + '}\n')
                output.write('#define ' + basename.upper() + '_NAME "' + basename + '"\n')
                output.write(cl.replace('RADIO_CONFIGURATION', basename.upper()))
                continue     # replaces previous generic name
            elif cl.startswith('//'):
                # add any configuration identifiers to the acdc dict
                acdc.update(dict(re.findall(pattern, cl)))
            output.write(cl)
    return acdc


def process_dirs(dirlist):
    '''
    process all of the subdirectories in the dirlist. For each
    name in dirlist, check if a radio_config.h file exists in the
    correct subdirectory, then process it and create two new files
    {'subdir'.c and 'subdir'.h) that contain code for access the
    configuration information.
    '''
    results = []
    for adir in dirlist:
        if not os.path.exists(adir+'.xml'):
            # zzz print('no WDS .xml file found', adir+'.xml')
            continue
        filepath = os.path.join(adir, 'src/application/radio_config.h')
        if not os.path.exists(filepath):
            # zzz print('no WDS source found',filepath)
            continue
        # zzz
        print(adir)
        # write out the .h and .c files for each valid directory
        with open(adir+'.h','w+') as output:
            output.write(comment_code)
            config_ids = process_config_file(adir, filepath, output)
        with open(adir+'.c','w+') as output:
            output.write(comment_code)
            output.write('#include <stdint.h>\n')
            output.write(typedef_code)
            output.write('#include "' + adir + '.h"')
            output.write(config_code.replace('SPECIAL_NAME',adir.upper()))
        results.append((adir, config_ids))
    return results

def sort_for_default(mydirs):
    count = 0
    base = ''
    for atup in mydirs:
        adir, acdc = atup
        base = os.path.basename(adir)
        if (base == DEFAULT_CONFIG_FILE):
            break
    if base:
        mydirs.remove(atup)
        mydirs.insert(0,atup)
    return mydirs

def write_global_config(dirlist):
    with open('wds_configs.c','w+') as output:
        output.write(comment_code)
        output.write('#include <stdint.h>\n')
        include_list = ''
        extern_list = ''
        string_list = ''
        for dirpath, acdc in sort_for_default(dirlist):
            dirbase = os.path.basename(dirpath)
            include_list += '#include "' + dirbase + '.h"\n'
            extern_list  += 'extern uint8_t const ' + dirbase.upper() + '_config[]' + ';\n'
            extern_list  += 'extern uint8_t const ' + dirbase.upper() + '_name[]' + ';\n'
            extern_list  += 'extern const wds_config_ids_t ' + dirbase.upper() + '_ids' + ';\n'
            string_list  += '   ' + dirbase.upper() + '_config' + ',\n'
            string_list  += '   ' + dirbase.upper() + '_name' + ',\n'
            string_list  += '   (uint8_t *) &' + dirbase.upper() + '_ids' + ',\n'
        output.write('#include <stdlib.h>\n')
        output.write('#include "wds_configs.h"\n')
        #output.write(include_list)
        output.write('\n')
        output.write(extern_list)
        output.write('\n')
        output.write('// const array of const strings, required definition and syntax\n')
        output.write('const uint8_t *const wds_radio_configs[] = {\n')
        output.write(string_list)
        output.write('    NULL, NULL, NULL,\n')
        output.write('};\n')
        output.write('\n')
        output.write(select_code)
    with open('wds_configs.h','w+') as output:
        output.write(comment_code)
        output.write('\n')
        output.write('#ifndef __WDS_CONFIG_H__\n')
        output.write('#define __WDS_CONFIG_H__\n')
        output.write('\n')
        output.write(typedef_code)
        output.write('\n')
        output.write(extern_code)
        output.write('\n#endif /* __WDS_CONFIG_H__ */\n')
    with open('Makefile.si446x', 'w+') as output:
        # output.write(comment_code)
        output.write('\n')
        output.write(
            'TOSMAKE_ADDITIONAL_INPUTS += $(PLATFORM_DIR)/hardware/si446x/wds_configs.c\n')
        output.write('\n')
        for dirpath, acdc in dirlist:
            dirbase = os.path.basename(dirpath)
            output.write(
                'TOSMAKE_ADDITIONAL_INPUTS += $(MM_ROOT)/tos/chips/si446x/WDS-files/' + dirbase + '.c\n')


def make_dir_copy(dlist, dest):
    for adir, acdc in dlist:
        for ftype in ['.h','.c']:
            fname = adir + ftype
            dname = os.path.join(dest, fname)
            if os.path.exists(dname):
                print('*** replaced',os.path.join(dname))
            if (DO_COPY):
                shutil.copy(fname, dname)

def make_one_copy(fname, destlist):
    for dname in destlist:
        if os.path.exists(dname):
            print('*** replaced',os.path.join(dname, fname))
        if (DO_COPY):
            shutil.copy(fname, dname)

def make_copies(dlst):
    '''
    capture important files as part of git trees of both the tag(mammark) and
    TagNet(RPi) versions.
    '''
    make_dir_copy(dlst, '../mm/tos/chips/si446x/WDS-files')
    make_dir_copy(dlst, '../TagNet/si446x/si446x/radioconfig/WDS-files')
    make_one_copy('wds_prep.py', ['../mm/tos/chips/si446x/WDS-files',
                                  '../TagNet/si446x/si446x/radioconfig/WDS-files'])
    make_one_copy('wds_configs.c', ['../mm/tos/platforms/mm6a/hardware/si446x',
                                    '../TagNet/si446x/si446x/radioconfig'])
    make_one_copy('wds_configs.h', ['../mm/tos/platforms/mm6a/hardware/si446x',
                                    '../TagNet/si446x/si446x/radioconfig'])
    make_one_copy('Makefile.si446x', ['../mm/tos/platforms/mm6a/hardware/si446x'])


if __name__ == '__main__':
    '''
    # process all of the directories found in the current working directory
    # and then write out the wds_configs.c file which contains the aggregate
    # of all of the separate configurations along with selector functions
    # used for runtime selection of one of the configurations processed.
    '''
    DO_COPY=True   # zzz for debug, control copy

    dirlist = process_dirs(os.listdir(os.path.abspath(os.path.relpath('.'))))
    if (dirlist):
        write_global_config(dirlist)
        make_copies(dirlist)