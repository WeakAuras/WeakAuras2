LibDataBroker is a small WoW addon library designed to provide a "MVC":http://en.wikipedia.org/wiki/Model-view-controller interface for use in various addons.
LDB's primary goal is to "detach" plugins for TitanPanel and FuBar from the display addon.
Plugins can provide data into a simple table, and display addons can receive callbacks to refresh their display of this data.
LDB also provides a place for addons to register "quicklaunch" functions, removing the need for authors to embed many large libraries to create minimap buttons.
Users who do not wish to be "plagued" by these buttons simply do not install an addon to render them.

Due to it's simple generic design, LDB can be used for any design where you wish to have an addon notified of changes to a table.

h2. Links

* "API documentation":http://github.com/tekkub/libdatabroker-1-1/wikis/api
* "Data specifications":http://github.com/tekkub/libdatabroker-1-1/wikis/data-specifications
* "Addons using LDB":http://github.com/tekkub/libdatabroker-1-1/wikis/addons-using-ldb
