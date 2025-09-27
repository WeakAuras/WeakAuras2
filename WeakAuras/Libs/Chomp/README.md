Chomp Message Library
=====================
The Chomp Message Library is a more-advanced and more-complex rewrite of the older (still maintained) ChatThrottleLib by mikk. The primary features that separate Chomp from CTL are the inclusion of Battle.net messaging functions and throttling, and advanced prefix handling and message splitting.

The Battle.net features are a logical extension of ChatThrottleLib's current capabilities, however the advanced prefix handling and message splitting for addon messages move significantly away from ChatThrottleLib's narrower, lightweight scope.

Including Chomp in Your AddOn
=============================
Embedding Chomp in your addon is supported, so long as your addon is not a LoadOnDemand addon. Chomp *must* be loaded prior to the PLAYER_LOGIN event firing, for safe handling of messages. Including Chomp in your loader addon is the preferred method of handling things, if you have to use LoadOnDemand.

To include Chomp, please add an entry for "Chomp\Chomp.xml" (note the file extension) to your addon's .toc file, with the proper extra path for where your addon keeps copies of libraries. Chomp is *not* guaranteed to always remain a single file of code.

Copyright and Permissions Notices
=================================
Copyright and permission notices are included in the headers of all substantial files. Files without copyright or permission notices are considered by the author to not meet the theshold of originality required for copyright, thus consisting solely of non-copyrightable material, and may be treated as such.

The year is *not* necessarily included in these copyright notices, as it is not required under the Berne Convention, and makes little sense for an author clearly identified by their legal name in a country where copyright term for an individual-authored work is limited based on the author's life. In the event of an author's death, the notices will be updated to reflect the year of death for that individual, assuming anyone is capable of doing so. Otherwise, obituaries and official records will need to be relied upon in the distant future.

In the cases of anonymous or pseudonymous contributions that cannot be tied to a legal name or a lifespan, the year of the contribution will be included in the notices for that particular author.
