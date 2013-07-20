#mikutter_haiku


##なにこれ
mikutterから簡易的に[はてなハイク][hatenahaiku]を扱うためのプラグインです。
+ 複数のキーワードを単一のタイムラインで閲覧可能
+ IDページヘの投稿に対応


##つかいかた
1. プラグインをインストロールします
2. 設定画面の「はてなハイク」で、はてなIDとAPIパスワードを入力します。コレは投稿のためだけに使用します。APIパスワードは[ハイクの設定画面][haiku_settings]で確認できます
3. 設定画面の「はてなハイク」で、ハイクJSON URLに購読したいタイムラインのJSON URLを入力します。書式は[はてなハイク REST API][haiku_rest_api]のタイムラインAPIの各ページを参考にしてください
4. 設定画面の「はてなハイク」にある他のオプションは、おこのみで設定します
5. 投稿コマンドは適宜ショートカットキーを割り当てます
6. ハイクタブで閲覧できたり、ハイクに投稿ができたら、これであなたも爽やかておくれライフ

####コマンド割り当て例
通常の投稿がCtrl+Enterに割り当てられている場合、次のような設定ではいかがでしょうか。
+ ハイクに投稿する: Shift+Enter
+ ハイクとTwitterに投稿する: Ctrl+Shift+Enter


##参考にしたりパクったりした
このプラグインは[yukkuri_sinai][yukkuritan]氏のmikutter_rssをベースに作成されました。
+ <https://github.com/yukkurisinai/mikutter_rss>

また、以下のページを参考にしたりパクったりしました。
+ <http://toshia.github.io/writing-mikutter-plugin/>
+ <http://mikutter.blogspot.jp/2011/11/ui.html>
+ <https://github.com/penguin2716/mikutter_update_with_media>
+ そのたいろいろ

[hatenahaiku]: http://h.hatena.ne.jp/
[haiku_settings]: http://h.hatena.ne.jp/setting/devices
[haiku_rest_api]: http://developer.hatena.ne.jp/ja/documents/haiku/apis/rest
[yukkuritan]: https://github.com/yukkurisinai
