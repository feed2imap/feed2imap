#!/usr/bin/ruby -w

$:.unshift File.join(File.dirname(__FILE__), '..', 'lib')

require 'test/unit'
require 'feed2imap/textconverters'

class TextConvertersText2HTMLTest < Test::Unit::TestCase
  def test_detecthtml
    assert('<p>aaa</p>'.html?)
    assert('aaaaa<p>a<p>aa</p>'.html?)
    assert('aaaaa<br>aa'.html?)
    assert(!'aaaaa<bra>aa'.html?)
    assert('aaaaa<br/>aa'.html?)
    assert('aaaaa<br  /    >aa'.html?)
    assert(!'aaa bbb ccc > ddd'.html?)
  end

  def test_text2html
    output = "<p>Les brouillons pour la spécification OpenAL 1.1 sont en ligne....</p>
<p>L'annonce et le thread sur la mailing list :
<a href=\"http://opensource.creative.com/pipermail/openal-devel/2005-February(...)\">http://opensource.creative.com/pipermail/openal-devel/2005-February(...)</a></p>
<p>Ou télécharger (en pdf ou sxw )
<a href=\"http://openal.org/documentation.html(...)\">http://openal.org/documentation.html(...)</a>
</p>"
    input = <<-EOF
Les brouillons pour la spécification OpenAL 1.1 sont en ligne....

L'annonce et le thread sur la mailing list :
http://opensource.creative.com/pipermail/openal-devel/2005-February(...)

Ou télécharger (en pdf ou sxw )
http://openal.org/documentation.html(...)
    EOF
    assert_equal(output, input.text2html)
  end

  def test_escapedhtmldetection
    assert('voir &lt;a href=&quote;lien&quote;&gt;'.escaped_html?)
    assert('&lt;img src=&quote;photo&quote;&gt;'.escaped_html?)
    assert('&lt;br&gt;'.escaped_html?)
    assert('&lt;br /&gt;'.escaped_html?)
  end
  def test_escapedhtml
    input = <<-EOF
                             It&#39;s been an exciting few weeks for
&lt;a href=&quot;http://opensolaris.org/os/community/dtrace/&quot;&gt;DTrace&lt;/a&gt;.
The party got started with
&lt;a href=&quot;http://netevil.org/&quot;&gt;Wez Furlong&#39;s&lt;/a&gt; new
&lt;a href=&quot;http://blogs.sun.com/roller/page/bmc?entry=dtrace_and_php_demonstrated&quot;&gt;PHP
DTrace provider&lt;/a&gt; at OSCON.  Then
&lt;a href=&quot;http://www.sitetronics.com/wordpress/&quot;&gt;Devon O&#39;Dell&lt;/a&gt;
announced that he was starting to work in earnest on a
&lt;a href=&quot;http://blogs.sun.com/roller/page/bmc?entry=dtrace_on_freebsd&quot;&gt;DTrace
port to FreeBSD&lt;/a&gt;.  And now,
&lt;a href=&quot;mailto:richlowe@richlowe.net&quot;&gt;Rich Lowe&lt;/a&gt;
has made available a prototype
&lt;a href=&quot;http://richlowe.net/~richlowe/patches/ruby-1.8.2-dtrace.diff&quot;&gt;Ruby
DTrace provider&lt;/a&gt;.
    EOF
    output=<<-EOF
                             It's been an exciting few weeks for\n<a href=\"http://opensolaris.org/os/community/dtrace/\">DTrace</a>.\nThe party got started with\n<a href=\"http://netevil.org/\">Wez Furlong's</a> new\n<a href=\"http://blogs.sun.com/roller/page/bmc?entry=dtrace_and_php_demonstrated\">PHP\nDTrace provider</a> at OSCON.  Then\n<a href=\"http://www.sitetronics.com/wordpress/\">Devon O'Dell</a>\nannounced that he was starting to work in earnest on a\n<a href=\"http://blogs.sun.com/roller/page/bmc?entry=dtrace_on_freebsd\">DTrace\nport to FreeBSD</a>.  And now,\n<a href=\"mailto:richlowe@richlowe.net\">Rich Lowe</a>\nhas made available a prototype\n<a href=\"http://richlowe.net/~richlowe/patches/ruby-1.8.2-dtrace.diff\">Ruby\nDTrace provider</a>.
    EOF
    assert_equal(output, input.text2html)
  end

  def test_unescapehtml
    assert_equal('<', '&lt;'.unescape_html)
  end

  def test_unescape_linuxfr
    input =<<-EOF
Le 17 août 2005, la quasi totalité de l'actuelle équipe de développement du CMS Open Source Mambo a annoncé, dans une lettre ouverte à la communauté, qu'elle préfère abandonner Mambo suite à la création de la fondation du même nom.&lt;br /&gt;
&lt;br /&gt;
En effet, les développeurs pensent que l'orientation de Mambo doit être dictée par les demandes de ses utilisateurs et les capacités des développeurs, or il semblerait que la Fondation Mambo soit conçue pour accorder le contrôle à la société Miro, une conception qui rend la coopération entre la Fondation et la communauté impossible.&lt;br /&gt;
&lt;br /&gt;
Dans les faits l'équipe quitte donc la table de la fondation Mambo pour continuer de développer le produit sous GPL, ce qui ressemble donc fort à un fork.


Le deuxième pique-nique du libre, organisé par Parinux est ouvert à tous les membres de la communauté du logiciel libre et à leur famille dans le sens large du terme.&lt;br /&gt;
&lt;br /&gt;
Il est prévu pour le samedi 27 août 2005 dans le Parc des Buttes-Chaumont. Rendez-vous de 12h00 à 12h15 à l'entrée. Après, il faudra trouver le groupe dans le parc. Un plan sur le site de Parinux devrait vous y aider.&lt;br /&gt;
&lt;br /&gt;
Les organisateurs vous demandent d'apporter quelque chose à boire et à manger et si vous le voulez, une couverture, ainsi que vos ballons de foot, de volley, pétanque, badminton, cerf-volant, etc.

 Comme à son habitude - même si ça a pris un peu plus de temps que prévu depuis l'annonce de Décembre 2000 - John Carmack peut aujourd'hui fournir le moteur du jeu &lt;a href=&quot;http://fr.wikipedia.org/wiki/Quake_3&quot;&gt;Quake 3&lt;/a&gt; en GPL. Il est maintenant officiellement disponible sur les ftp de id software comme annoncé par linuX-gamers.&lt;br /&gt;
&lt;br /&gt;
John Carmack avait effectué la semaine dernière à QuakeCon 2005 l'annonce de &quot;cette disponibilté des sources sous une semaine&quot;. Quake III rejoint ainsi les Quake I et II dont le moteur est GPL depuis quelques temps, pour la plus grande joie des amateurs de jeux FPS (First Person Shooter ou &lt;a href=&quot;http://fr.wikipedia.org/wiki/Jeu_de_tir_subjectif&quot;&gt;jeu de tir subjectif en 3D&lt;/a&gt; ou encore Quake-like).&lt;br /&gt;
&lt;br /&gt;
Il y a quelques temps, InternetActu a aussi effectué une synthèse des raisons d'avoir des jeux libres (dont Nexuiz basé sur quake1) montrant l'avancement des réflexions sur le sujet.

    Vous en avez rêvé, vous l'avez réclamée... Elle est là : &lt;br /&gt;
&lt;br /&gt;
LA dépêche cinéma sur le tout premier film de Garth Jennings : H2G2 &lt;b&gt;H&lt;/b&gt;itch &lt;b&gt;H&lt;/b&gt;icker's &lt;b&gt;G&lt;/b&gt;uide to the &lt;b&gt;G&lt;/b&gt;alaxy, en français : H2G2 Le Guide du Voyageur Galactique.&lt;br /&gt;
&lt;br /&gt;
Ce film est - comme tout bon geek qui se respecte le sait - l'adaptation au cinéma d'une émission radiophonique créée par Douglas Adams. Entre temps, on a eu le droit à cinq romans (constituant une trilogie...), une série TV, un jeu vidéo.&lt;br /&gt;
&lt;br /&gt;
Mais je m'égare : pour résumer le film (mais encore une fois est-ce bien là peine ?), on suit donc les pérégrinations intergalactiques du terrien Arthur Dent, après que la terre a été rayée du système solaire. Celui-ci est accompagné du président de la galaxie, de Ford Prefect, un ami extraterrestre en provenance d'une petite planète près de Bételgeuse, de sa petite amie qui l'a lâché quelques heures après l'avoir rencontré, et de Marvin, un robot dépressif.&lt;br /&gt;
&lt;br /&gt;
Et tout ça, pour quoi me demanderez-vous ? Mais voyons, trouver la question ultime de la vie, l'univers et tout le reste.

    Les deux grands constructeurs ont mis à jour récemment leurs pilotes propriétaires pour GNU/Linux (pour les architectures supportées).&lt;br /&gt;
&lt;br /&gt;
ATI : Sortie le 18/08 de la version 8.16.20 pour X86 et X86-64&lt;br /&gt;
Une grosse mise à jour pour le constructeur canadien :&lt;br /&gt;
Au menu :&lt;br /&gt;
&lt;ul&gt;&lt;br /&gt;
&lt;li&gt;Amélioration des performances&lt;/li&gt;&lt;li&gt;Support du noyau 2.6.12&lt;/li&gt;&lt;li&gt;Support de GCC 4.0&lt;/li&gt;&lt;li&gt;Correction de certains bugs :&lt;br /&gt;
&lt;ul&gt;&lt;br /&gt;
 &lt;li&gt;Résolution des problèmes systèmes avec HDTV et les gros fichiers vidéos.&lt;/li&gt; &lt;li&gt;Le curseur souris n'apparaît plus sur les deux écrans à la fois en multi-tête.&lt;/li&gt;&lt;li&gt;Le panoramique sur le deuxième écran est maintenant disponible en utilisant les pseudo-couleurs et le mode clone.&lt;/li&gt; &lt;li&gt;Les machines sous Red Hat Enterprise Linux workstation 4 Update 1 et possédant 4 Go ou plus de mémoire n'ont plus de problème lors du chargement du pilote.&lt;/li&gt; &lt;li&gt;Le support de l'Overlay est disponible sur les machines 64 bits&lt;/li&gt; &lt;li&gt;Des fuites mémoires pour PCIe ont été corrigés.&lt;/li&gt;&lt;br /&gt;
&lt;/ul&gt;&lt;br /&gt;
&lt;/li&gt;&lt;/ul&gt;&lt;br /&gt;
&lt;br /&gt;
NVIDIA : le 09/08 sortait la version 1.0-7676 pour X86 et AMD64&lt;br /&gt;
Ce pilote n'est qu'un correctif du précédent, il règle le problème d'horloge pour les GeForce 7800 GTX (donc inutile pour tous ceux qui n'ont pas cette carte).

Le 17 août 2005 est sorti sur vos grands écrans le dernier film de Michael Bay : The Island. (ndla : L'île).&lt;br /&gt;
&lt;br /&gt;
Disons le tout de suite, vous ne verrez pas vraiment une île paradisiaque avec plage de sable fin et cocotiers à perte de vue.&lt;br /&gt;
Non, car l'heure est grave : un cataclysme a ravagé la planète, qui se trouve maintenant contaminée.  &lt;br /&gt;
&lt;br /&gt;
Heureusement, certaines personnes survivent et sont ramenées dans une colonie fermée où vivent nos deux héros, incarnés respectivement par  Ewan McGregor et  Scarlett Johansson.&lt;br /&gt;
Pour illuminer une vie qui serait trop désespérante, chaque personne participe à une loterie, qui permet à son heureux gagnant de quitter la colonie pour une fabuleuse île (non contaminée), où la vie est plus douce.&lt;br /&gt;
&lt;br /&gt;
Mais bientôt, notre cher Ewan commence à se poser des questions et va découvrir la réalité terrifiante de The Island ....

    Un long article de The Register revient sur le &lt;i&gt;&quot;Sun's Linux killer&quot;&lt;/i&gt;, à savoir Solaris 10. Le but de l'auteur est davantage de réaliser un compte-rendu d'utilisation qu'un comparatif, il n'y a notamment (et délibérément) pas de benchmark qui pourraient étayer les dires de l'auteur (Thomas C Green). Il faut donc garder en tête le côté parfaitement subjectif de l'article.&lt;br /&gt;
&lt;br /&gt;
L'auteur souligne pour commencer que si, actuellement et sur la cible visée (les PC), GNU/Linux est loin devant, Sun peut se donner les moyens de rattraper son retard ... s'il en a le désir.&lt;br /&gt;
&lt;br /&gt;
Pour résumer les points forts de Solaris sont :&lt;ul&gt;&lt;li&gt;la maturité d'Unix, le système est tout particulièrement stable et il est difficile de le faire s'écrouler.&lt;/li&gt;&lt;li&gt;la rapidité (subjectif)&lt;/li&gt;&lt;li&gt;la qualité de &lt;a href=&quot;http://opensolaris.org/os/community/dtrace/&quot;&gt;DTrace&lt;/a&gt;&lt;/li&gt;&lt;li&gt;les zones virtuelles (&lt;i&gt;containers&lt;/i&gt;) qui permettent de gérer plus finement les ressources allouées aux programmes&lt;/li&gt;&lt;li&gt;c'est Sun, entendre par là que ça passera toujours mieux auprès d'un DSI de savoir qu'il y a le support de Sun derrière&lt;/li&gt;&lt;/ul&gt;&lt;br /&gt;
Les points faibles sont :&lt;ul&gt;&lt;li&gt;la phase d'installation n'est pas meilleure qu'une bonne distribution GNU/Linux&lt;/li&gt;&lt;li&gt;le support du matériel limité, l'exemple de la très répandue SBLive est parlant.&lt;/li&gt;&lt;li&gt;les choix dans les logiciels proposés (subjectif on vous a dit)&lt;/li&gt;&lt;li&gt;la jeunesse globale du projet et le côté commercial qui rebute encore la communauté&lt;/li&gt;&lt;/ul&gt;&lt;br /&gt;
Pour conclure, Solaris 10 est plus un bon concurrent en devenir plutôt qu'un &lt;i&gt;&quot;GNU/Linux killer&quot;&lt;/i&gt; cependant il y a de bonnes idées dans le système qu'il conviendrait d'étudier de près.

    J'avais décidé de ne plus utiliser mon &lt;a href=&quot;http://www.rfi.fr/actufr/articles/062/article_34098.asp&quot;&gt;téléphone&lt;/a&gt; et surtout pas mon mobile qui peut fournir &lt;a href=&quot;http://www.transfert.net/a4879&quot;&gt;ma position en continu&lt;/a&gt;. J'avais banni les cartes de fidélité des supermarchés qui permettaient de collecter les informations sur mes goûts et de les revendre. J'évitais de même les sondages divers commerciaux. Je me disais qu'en payant en liquide (avec un &lt;a href=&quot;http://www.liberation.fr/page.php?Article=315139&quot;&gt;risque de contrefaçon sur les billets&lt;/a&gt; certes) et en n'utilisant pas &lt;a href=&quot;http://www.lexpansion.com/art/2661.80555.0.html&quot;&gt;de pass dans le métro&lt;/a&gt;, je préserverais un peu de ma liberté. Poussant le raisonnement au bout, j'avais décidé d'organiser régulièrement des brèves rencontres avec des inconnus pour mettre dans un pot commun mes billets et mes tickets de métro, les mélanger et repartir ainsi avec des numéros de série anonymisés, par peur &lt;a href=&quot;http://www.eurobilltracker.com/&quot;&gt;d'être suivi&lt;/a&gt;, et puis cela me permettait d'échanger des empreintes &lt;a href=&quot;http://www.gnupg.org/(fr)/documentation/faqs.html#q1.1&quot;&gt;GnuPG&lt;/a&gt;.&lt;br /&gt;
&lt;br /&gt;
Bien sûr j'utilisais des &lt;a href=&quot;http://www.gnu.org/philosophy/free-sw.fr.html&quot;&gt;logiciels libres&lt;/a&gt;, car pourquoi ferais-je confiance à des logiciels propriétaires boîtes noires, contenant potentiellement &lt;a href=&quot;http://www.transfert.net/a3504&quot;&gt;des portes dérobées&lt;/a&gt; ou des &lt;a href=&quot;http://fr.wikipedia.org/wiki/Spyware&quot;&gt;espiogiciels&lt;/a&gt;. Je ne communiquais qu'en &lt;a href=&quot;https://linuxfr.org&quot;&gt;https&lt;/a&gt;, mes courriels étaient tous chiffrés, mes partitions aussi, et de toute façon mes remarques sur la météo et le sexe opposé ne circulaient que dans des images de gnous en utilisant de la &lt;a href=&quot;http://fr.wikipedia.org/wiki/St%C3%A9ganographie&quot;&gt;stéganographie&lt;/a&gt;. Et je me croyais tranquille.&lt;br /&gt;
&lt;br /&gt;
C'était sans compter sur le déploiement de nouveaux ordinateurs &lt;a href=&quot;http://linuxfr.org/2003/01/10/10927.html&quot;&gt;équipés en standard de TPM&lt;/a&gt; (oui l'informatique dite « de confiance », &lt;a href=&quot;http://www.lebars.org/sec/tcpa-faq.fr.html&quot;&gt;TCPA/Palladium&lt;/a&gt;, &lt;a href=&quot;http://ccomb.free.fr/TCPA_Stallman_fr.html&quot;&gt;ayez confiance&lt;/a&gt;, tout ça) qui étaient déjà sur le marché. Et les &lt;a href=&quot;http://www.eff.org/deeplinks/archives/003835.php&quot;&gt;imprimantes qui se mettaient à bavasser&lt;/a&gt; aussi. Sans compter aussi que &lt;a href=&quot;http://www.edri.org/edrigram/number3.15/commission&quot;&gt;certains aimeraient bien collecter toutes les données de trafic internet et téléphonique&lt;/a&gt; (le courrier postal n'intéresse personne...), en évoquant des &lt;a href=&quot;http://linuxfr.org/2005/07/31/19368.html&quot;&gt;questions de sécurité&lt;/a&gt;, voire créer des &lt;a href=&quot;http://eucd.info/pr-2005-03-07.fr.php&quot;&gt;e-milices sur les réseaux&lt;/a&gt; (de toute façon on me proposait déjà de confier &lt;a href=&quot;http://www.schneier.com/blog/archives/2005/07/uk_police_and_e.html&quot;&gt;mes clés de chiffrement aux forces de police&lt;/a&gt;, sachant qu'&lt;a href=&quot;http://www.edri.org/edrigram/number3.13/backdoor&quot;&gt;ils savaient s'en passer si besoin&lt;/a&gt;). Ceci dit les &lt;a href=&quot;http://www.foruminternet.org/activites_evenements/lire.phtml?id=111&quot;&gt;débats sur la nouvelle carte d'identité électronique en France&lt;/a&gt; avaient laissé perplexe (identifiant unique, données biométriques, mélange de l'officiel et du commercial, etc.).&lt;br /&gt;
&lt;br /&gt;
De son côté l'industrie de la musique et du cinéma promettait des mesures techniques de protection pour décider si et quand et combien de fois je pourrais lire le DVD que j'avais acheté, et avec quel matériel et quel logiciel, en arguant des cataclysmes apocalyptiques et tentaculaires causés par des lycéens de 12 ans ; on me promettait même &lt;a href=&quot;http://rss.zdnet.fr/actualites/informatique/0,39040745,39251935,00.htm?xtor=1&quot;&gt;des identifiants uniques sur chaque disque et un blocage de la copie privée pourtant légale&lt;/a&gt;. Finalement on me proposait de bénéficier des puces d'identification par radio-fréquences &lt;a href=&quot;http://fr.wikipedia.org/wiki/RFID&quot;&gt;RFID&lt;/a&gt; aux usages multiples : &lt;a href=&quot;http://yro.slashdot.org/yro/05/07/28/1456246.shtml?tid=158&amp;amp;tid=126&amp;amp;tid=193&quot;&gt;traçage des étrangers&lt;/a&gt;, contrôle des papiers d'identité, implantation sous-cutanée...&lt;br /&gt;
&lt;br /&gt;
Bah il ne me restait plus qu'à aller poser devant les caméras dans la rue (&lt;a href=&quot;http://www.lemonde.fr/web/article/0,1-0@2-3224,36-677627@51-675643,0.html&quot;&gt;Paris&lt;/a&gt;, &lt;a href=&quot;http://www.ldh-toulon.net/imprimer.php3?id_article=798&quot;&gt;Londres&lt;/a&gt;, etc.), et à reprendre des &lt;a href=&quot;http://en.wikipedia.org/wiki/Tinfoil_hat&quot;&gt;pilules&lt;/a&gt;. Enfin ça ou essayer d'améliorer les choses.&lt;br /&gt;
&lt;br /&gt;
« Nous avons neuf mois de vie privée avant de naître, ça devrait nous suffire. » (Heathcote Williams)&lt;br /&gt;
&lt;br /&gt;
« Même les &lt;a href=&quot;http://unix.rulez.org/~calver/pictures/worldconspiracy.jpg&quot;&gt;paranoïaques&lt;/a&gt; ont des ennemis. » (Albert Einstein)
    EOF
    output = <<-EOF
Le 17 août 2005, la quasi totalité de l'actuelle équipe de développement du CMS Open Source Mambo a annoncé, dans une lettre ouverte à la communauté, qu'elle préfère abandonner Mambo suite à la création de la fondation du même nom.<br />
<br />
En effet, les développeurs pensent que l'orientation de Mambo doit être dictée par les demandes de ses utilisateurs et les capacités des développeurs, or il semblerait que la Fondation Mambo soit conçue pour accorder le contrôle à la société Miro, une conception qui rend la coopération entre la Fondation et la communauté impossible.<br />
<br />
Dans les faits l'équipe quitte donc la table de la fondation Mambo pour continuer de développer le produit sous GPL, ce qui ressemble donc fort à un fork.


Le deuxième pique-nique du libre, organisé par Parinux est ouvert à tous les membres de la communauté du logiciel libre et à leur famille dans le sens large du terme.<br />
<br />
Il est prévu pour le samedi 27 août 2005 dans le Parc des Buttes-Chaumont. Rendez-vous de 12h00 à 12h15 à l'entrée. Après, il faudra trouver le groupe dans le parc. Un plan sur le site de Parinux devrait vous y aider.<br />
<br />
Les organisateurs vous demandent d'apporter quelque chose à boire et à manger et si vous le voulez, une couverture, ainsi que vos ballons de foot, de volley, pétanque, badminton, cerf-volant, etc.

 Comme à son habitude - même si ça a pris un peu plus de temps que prévu depuis l'annonce de Décembre 2000 - John Carmack peut aujourd'hui fournir le moteur du jeu <a href="http://fr.wikipedia.org/wiki/Quake_3">Quake 3</a> en GPL. Il est maintenant officiellement disponible sur les ftp de id software comme annoncé par linuX-gamers.<br />
<br />
John Carmack avait effectué la semaine dernière à QuakeCon 2005 l'annonce de "cette disponibilté des sources sous une semaine". Quake III rejoint ainsi les Quake I et II dont le moteur est GPL depuis quelques temps, pour la plus grande joie des amateurs de jeux FPS (First Person Shooter ou <a href="http://fr.wikipedia.org/wiki/Jeu_de_tir_subjectif">jeu de tir subjectif en 3D</a> ou encore Quake-like).<br />
<br />
Il y a quelques temps, InternetActu a aussi effectué une synthèse des raisons d'avoir des jeux libres (dont Nexuiz basé sur quake1) montrant l'avancement des réflexions sur le sujet.

    Vous en avez rêvé, vous l'avez réclamée... Elle est là : <br />
<br />
LA dépêche cinéma sur le tout premier film de Garth Jennings : H2G2 <b>H</b>itch <b>H</b>icker's <b>G</b>uide to the <b>G</b>alaxy, en français : H2G2 Le Guide du Voyageur Galactique.<br />
<br />
Ce film est - comme tout bon geek qui se respecte le sait - l'adaptation au cinéma d'une émission radiophonique créée par Douglas Adams. Entre temps, on a eu le droit à cinq romans (constituant une trilogie...), une série TV, un jeu vidéo.<br />
<br />
Mais je m'égare : pour résumer le film (mais encore une fois est-ce bien là peine ?), on suit donc les pérégrinations intergalactiques du terrien Arthur Dent, après que la terre a été rayée du système solaire. Celui-ci est accompagné du président de la galaxie, de Ford Prefect, un ami extraterrestre en provenance d'une petite planète près de Bételgeuse, de sa petite amie qui l'a lâché quelques heures après l'avoir rencontré, et de Marvin, un robot dépressif.<br />
<br />
Et tout ça, pour quoi me demanderez-vous ? Mais voyons, trouver la question ultime de la vie, l'univers et tout le reste.

    Les deux grands constructeurs ont mis à jour récemment leurs pilotes propriétaires pour GNU/Linux (pour les architectures supportées).<br />
<br />
ATI : Sortie le 18/08 de la version 8.16.20 pour X86 et X86-64<br />
Une grosse mise à jour pour le constructeur canadien :<br />
Au menu :<br />
<ul><br />
<li>Amélioration des performances</li><li>Support du noyau 2.6.12</li><li>Support de GCC 4.0</li><li>Correction de certains bugs :<br />
<ul><br />
 <li>Résolution des problèmes systèmes avec HDTV et les gros fichiers vidéos.</li> <li>Le curseur souris n'apparaît plus sur les deux écrans à la fois en multi-tête.</li><li>Le panoramique sur le deuxième écran est maintenant disponible en utilisant les pseudo-couleurs et le mode clone.</li> <li>Les machines sous Red Hat Enterprise Linux workstation 4 Update 1 et possédant 4 Go ou plus de mémoire n'ont plus de problème lors du chargement du pilote.</li> <li>Le support de l'Overlay est disponible sur les machines 64 bits</li> <li>Des fuites mémoires pour PCIe ont été corrigés.</li><br />
</ul><br />
</li></ul><br />
<br />
NVIDIA : le 09/08 sortait la version 1.0-7676 pour X86 et AMD64<br />
Ce pilote n'est qu'un correctif du précédent, il règle le problème d'horloge pour les GeForce 7800 GTX (donc inutile pour tous ceux qui n'ont pas cette carte).

Le 17 août 2005 est sorti sur vos grands écrans le dernier film de Michael Bay : The Island. (ndla : L'île).<br />
<br />
Disons le tout de suite, vous ne verrez pas vraiment une île paradisiaque avec plage de sable fin et cocotiers à perte de vue.<br />
Non, car l'heure est grave : un cataclysme a ravagé la planète, qui se trouve maintenant contaminée.  <br />
<br />
Heureusement, certaines personnes survivent et sont ramenées dans une colonie fermée où vivent nos deux héros, incarnés respectivement par  Ewan McGregor et  Scarlett Johansson.<br />
Pour illuminer une vie qui serait trop désespérante, chaque personne participe à une loterie, qui permet à son heureux gagnant de quitter la colonie pour une fabuleuse île (non contaminée), où la vie est plus douce.<br />
<br />
Mais bientôt, notre cher Ewan commence à se poser des questions et va découvrir la réalité terrifiante de The Island ....

    Un long article de The Register revient sur le <i>"Sun's Linux killer"</i>, à savoir Solaris 10. Le but de l'auteur est davantage de réaliser un compte-rendu d'utilisation qu'un comparatif, il n'y a notamment (et délibérément) pas de benchmark qui pourraient étayer les dires de l'auteur (Thomas C Green). Il faut donc garder en tête le côté parfaitement subjectif de l'article.<br />
<br />
L'auteur souligne pour commencer que si, actuellement et sur la cible visée (les PC), GNU/Linux est loin devant, Sun peut se donner les moyens de rattraper son retard ... s'il en a le désir.<br />
<br />
Pour résumer les points forts de Solaris sont :<ul><li>la maturité d'Unix, le système est tout particulièrement stable et il est difficile de le faire s'écrouler.</li><li>la rapidité (subjectif)</li><li>la qualité de <a href="http://opensolaris.org/os/community/dtrace/">DTrace</a></li><li>les zones virtuelles (<i>containers</i>) qui permettent de gérer plus finement les ressources allouées aux programmes</li><li>c'est Sun, entendre par là que ça passera toujours mieux auprès d'un DSI de savoir qu'il y a le support de Sun derrière</li></ul><br />
Les points faibles sont :<ul><li>la phase d'installation n'est pas meilleure qu'une bonne distribution GNU/Linux</li><li>le support du matériel limité, l'exemple de la très répandue SBLive est parlant.</li><li>les choix dans les logiciels proposés (subjectif on vous a dit)</li><li>la jeunesse globale du projet et le côté commercial qui rebute encore la communauté</li></ul><br />
Pour conclure, Solaris 10 est plus un bon concurrent en devenir plutôt qu'un <i>"GNU/Linux killer"</i> cependant il y a de bonnes idées dans le système qu'il conviendrait d'étudier de près.

    J'avais décidé de ne plus utiliser mon <a href="http://www.rfi.fr/actufr/articles/062/article_34098.asp">téléphone</a> et surtout pas mon mobile qui peut fournir <a href="http://www.transfert.net/a4879">ma position en continu</a>. J'avais banni les cartes de fidélité des supermarchés qui permettaient de collecter les informations sur mes goûts et de les revendre. J'évitais de même les sondages divers commerciaux. Je me disais qu'en payant en liquide (avec un <a href="http://www.liberation.fr/page.php?Article=315139">risque de contrefaçon sur les billets</a> certes) et en n'utilisant pas <a href="http://www.lexpansion.com/art/2661.80555.0.html">de pass dans le métro</a>, je préserverais un peu de ma liberté. Poussant le raisonnement au bout, j'avais décidé d'organiser régulièrement des brèves rencontres avec des inconnus pour mettre dans un pot commun mes billets et mes tickets de métro, les mélanger et repartir ainsi avec des numéros de série anonymisés, par peur <a href="http://www.eurobilltracker.com/">d'être suivi</a>, et puis cela me permettait d'échanger des empreintes <a href="http://www.gnupg.org/(fr)/documentation/faqs.html#q1.1">GnuPG</a>.<br />
<br />
Bien sûr j'utilisais des <a href="http://www.gnu.org/philosophy/free-sw.fr.html">logiciels libres</a>, car pourquoi ferais-je confiance à des logiciels propriétaires boîtes noires, contenant potentiellement <a href="http://www.transfert.net/a3504">des portes dérobées</a> ou des <a href="http://fr.wikipedia.org/wiki/Spyware">espiogiciels</a>. Je ne communiquais qu'en <a href="https://linuxfr.org">https</a>, mes courriels étaient tous chiffrés, mes partitions aussi, et de toute façon mes remarques sur la météo et le sexe opposé ne circulaient que dans des images de gnous en utilisant de la <a href="http://fr.wikipedia.org/wiki/St%C3%A9ganographie">stéganographie</a>. Et je me croyais tranquille.<br />
<br />
C'était sans compter sur le déploiement de nouveaux ordinateurs <a href="http://linuxfr.org/2003/01/10/10927.html">équipés en standard de TPM</a> (oui l'informatique dite « de confiance », <a href="http://www.lebars.org/sec/tcpa-faq.fr.html">TCPA/Palladium</a>, <a href="http://ccomb.free.fr/TCPA_Stallman_fr.html">ayez confiance</a>, tout ça) qui étaient déjà sur le marché. Et les <a href="http://www.eff.org/deeplinks/archives/003835.php">imprimantes qui se mettaient à bavasser</a> aussi. Sans compter aussi que <a href="http://www.edri.org/edrigram/number3.15/commission">certains aimeraient bien collecter toutes les données de trafic internet et téléphonique</a> (le courrier postal n'intéresse personne...), en évoquant des <a href="http://linuxfr.org/2005/07/31/19368.html">questions de sécurité</a>, voire créer des <a href="http://eucd.info/pr-2005-03-07.fr.php">e-milices sur les réseaux</a> (de toute façon on me proposait déjà de confier <a href="http://www.schneier.com/blog/archives/2005/07/uk_police_and_e.html">mes clés de chiffrement aux forces de police</a>, sachant qu'<a href="http://www.edri.org/edrigram/number3.13/backdoor">ils savaient s'en passer si besoin</a>). Ceci dit les <a href="http://www.foruminternet.org/activites_evenements/lire.phtml?id=111">débats sur la nouvelle carte d'identité électronique en France</a> avaient laissé perplexe (identifiant unique, données biométriques, mélange de l'officiel et du commercial, etc.).<br />
<br />
De son côté l'industrie de la musique et du cinéma promettait des mesures techniques de protection pour décider si et quand et combien de fois je pourrais lire le DVD que j'avais acheté, et avec quel matériel et quel logiciel, en arguant des cataclysmes apocalyptiques et tentaculaires causés par des lycéens de 12 ans ; on me promettait même <a href="http://rss.zdnet.fr/actualites/informatique/0,39040745,39251935,00.htm?xtor=1">des identifiants uniques sur chaque disque et un blocage de la copie privée pourtant légale</a>. Finalement on me proposait de bénéficier des puces d'identification par radio-fréquences <a href="http://fr.wikipedia.org/wiki/RFID">RFID</a> aux usages multiples : <a href="http://yro.slashdot.org/yro/05/07/28/1456246.shtml?tid=158&amp;tid=126&amp;tid=193">traçage des étrangers</a>, contrôle des papiers d'identité, implantation sous-cutanée...<br />
<br />
Bah il ne me restait plus qu'à aller poser devant les caméras dans la rue (<a href="http://www.lemonde.fr/web/article/0,1-0@2-3224,36-677627@51-675643,0.html">Paris</a>, <a href="http://www.ldh-toulon.net/imprimer.php3?id_article=798">Londres</a>, etc.), et à reprendre des <a href="http://en.wikipedia.org/wiki/Tinfoil_hat">pilules</a>. Enfin ça ou essayer d'améliorer les choses.<br />
<br />
« Nous avons neuf mois de vie privée avant de naître, ça devrait nous suffire. » (Heathcote Williams)<br />
<br />
« Même les <a href="http://unix.rulez.org/~calver/pictures/worldconspiracy.jpg">paranoïaques</a> ont des ennemis. » (Albert Einstein)
    EOF
    assert_equal(output, input.unescape_html)
  end

  def test_unescape_bmc
    input = <<-EOF
So MIT&#39;s 
&lt;a href=&quot;http://www.techreview.com/&quot;&gt;Technology Review&lt;/a&gt; has named me as one of their
&lt;a href=&quot;http://www.technologyreview.com/articles/05/10/issue/feature_tr35.asp&quot;&gt;TR35&lt;/a&gt; -- the top 35 innovators under the age of thirty-five.  It&#39;s a great honor, especially because the other
honorees are &lt;i&gt;actually&lt;/i&gt; working on things like
&lt;a href=&quot;http://www.wi.mit.edu/research/fellows/brummelkamp.html&quot;&gt;cures for cancer&lt;/a&gt;
and
&lt;a href=&quot;http://www.pw.utc.com/shock-system/popsci.html&quot;&gt;rocket science&lt;/a&gt; -- domains
that I have known only as rhetorical flourish.
Should you like to hear me make a jackass out of myself on the subject, you might
want to check out
&lt;a href=&quot;http://blogs.sun.com/roller/page/rgiles&quot;&gt;Richard Giles&lt;/a&gt;&#39;s
&lt;a href=&quot;http://blogs.sun.com/roller/page/rgiles?entry=i_o_podcast_0003_bryan&quot;&gt;latest I/O podcast&lt;/a&gt;,
in which he interviewed me about the award.
    EOF

    output = <<-EOF
So MIT's 
<a href="http://www.techreview.com/">Technology Review</a> has named me as one of their
<a href="http://www.technologyreview.com/articles/05/10/issue/feature_tr35.asp">TR35</a> -- the top 35 innovators under the age of thirty-five.  It's a great honor, especially because the other
honorees are <i>actually</i> working on things like
<a href="http://www.wi.mit.edu/research/fellows/brummelkamp.html">cures for cancer</a>
and
<a href="http://www.pw.utc.com/shock-system/popsci.html">rocket science</a> -- domains
that I have known only as rhetorical flourish.
Should you like to hear me make a jackass out of myself on the subject, you might
want to check out
<a href="http://blogs.sun.com/roller/page/rgiles">Richard Giles</a>'s
<a href="http://blogs.sun.com/roller/page/rgiles?entry=i_o_podcast_0003_bryan">latest I/O podcast</a>,
in which he interviewed me about the award.
    EOF
    assert_equal(output, input.unescape_html)
  end

  def test_unescape_vnoel
    input = <<-EOF
&lt;div&gt;How are you supposed to trust these guys ?&lt;img src=&quot;http://members.cox.net/vnoel/weblog/uploaded_images/Screenshot-Flight%20Details-798819.png&quot; /&gt;
&lt;/div&gt;
    EOF

    output = <<-EOF
<div>How are you supposed to trust these guys ?<img src="http://members.cox.net/vnoel/weblog/uploaded_images/Screenshot-Flight%20Details-798819.png" />
</div>
    EOF
    assert_equal(output, input.unescape_html)
  end
end
