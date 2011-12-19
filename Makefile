ERL ?= erl
APP := erlcron

.PHONY: deps

all: deps compile

compile:
	@./rebar compile

debug:
	@./rebar debug_info=1 compile

deps:
	@./rebar get-deps

app:
	@./rebar compile skip_deps=true

webstart: app
	exec erl -pa $(PWD)/ebin -pa $(PWD)/deps/*/ebin -config $(PWD)/priv/app.config -s erlcron

clean:
	@./rebar clean

distclean: clean
	@./rebar delete-deps

test:
	@./rebar compile skip_deps=true eunit

docs:
	@erl -noshell -run edoc_run application '$(APP)' '"."' '[]'

APPS = kernel stdlib sasl erts ssl tools mnesia os_mon runtime_tools crypto inets \
	xmerl webtool snmp public_key eunit syntax_tools compiler
COMBO_PLT = $(HOME)/.evo_core_combo_dialyzer_plt

# ----------------------------------------------------------------------
#                       GETTEXT SUPPORT
#                       ---------------
# GETTEXT_EBIN
#  Path to the gettext ebin directory.
#
# GETTEXT_PO_DIR
#  Set this to a directory where we have write access.
#  This directory will hold all po-files and the dets DB file.
#  Example: 'GETTEXT_DIR=$(MY_APP_DIR)/priv'
#
# GETTEXT_DEF_LANG
#  Set the language code of the default language (e.g en,sv,...), 
#  i.e the language you are using in the string arguments to the
#  ?TXT macros. Example: 'GETTEXT_DEF_LANG=en'
#
# GETTEXT_TMP_NAME
#  Set this to an arbitrary name.
#  It will create a subdirectory to $(GETTEXT_DIR) where
#  the intermediary files of this example will end up.
#  Example: 'GETTEXT_TMP_NAME=tmp'
#

gettext: compile
	  @rm -f $(GETTEXT_PO_DIR)/lang/$(GETTEXT_TMP_NAME)/epot.dets;
	  @erl -noshell -pa $(GETTEXT_EBIN) -s gettext_compile epot2po;
	  @install $(GETTEXT_PO_DIR)/lang/$(GETTEXT_TMP_NAME)/$(GETTEXT_DEF_LANG)/gettext.po $(GETTEXT_PO_DIR)/lang/default/$(GETTEXT_DEF_LANG)/gettext.po;
	  @rm -rf $(GETTEXT_PO_DIR)/lang/$(GETTEXT_TMP_NAME)

# ----------------------------------------------------------------------
#                       DIALYZER SUPPORT
#                       ---------------

check_plt: debug
	dialyzer --check_plt --plt $(COMBO_PLT) --apps $(APPS)

build_plt: debug
	dialyzer --build_plt --output_plt $(COMBO_PLT) --apps $(APPS)

dialyzer: debug
	@echo
	@echo Use "'make check_plt'" to check PLT prior to using this target.
	@echo Use "'make build_plt'" to build PLT prior to using this target.
	@echo
	@sleep 1
	dialyzer -Wno_return --plt $(COMBO_PLT) ebin | \
	    fgrep -v -f ./dialyzer.ignore-warnings

cleanplt:
	@echo 
	@echo "Are you sure?  It takes about 1/2 hour to re-build."
	@echo Deleting $(COMBO_PLT) in 5 seconds.
	@echo 
	sleep 5
	rm $(COMBO_PLT)