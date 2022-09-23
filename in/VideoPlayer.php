<?php
// See http://www.mediawiki.org/wiki/Extension:VideoPlayer for more information.

$wgExtensionFunctions[] = 'VideoPlayer';
$wgExtensionCredits['parserhook'][] = array(
    'name'          => 'VideoPlayer',
    'description'   => 'Display video players for youtube, dailymotion, vimeo, google, etc...',
    'author'        => 'Joachim Chauveheid',
    'version'       => 1.0 
);

function VideoPlayer() {
    global $wgParser;
    $wgParser->setHook('video', 'renderVideoPlayer');
}

function renderVideoPlayer($input, $args) {
    $url = array();
    $url['allocine']    = 'http://www.allocine.fr/blogvision/%1$s';
    $url['blip']        = 'http://blip.tv/play/%1$s';
    $url['dailymotion'] = 'http://www.dailymotion.com/swf/%1$s?syndication=112040';
    $url['facebook']    = 'http://www.facebook.com/v/%1$';
    $url['gametrailers']= 'http://www.gametrailers.com/remote_wrap.php?mid=%$1s';
    $url['googlevideo'] = 'http://video.google.com/googleplayer.swf?docId=%1$d';
    $url['html5'  ]     = '%1$s';
    $url['metacafe']    = 'http://www.metacafe.com/fplayer/%1$d/' . (isset($args['vid']) ? $args['vid'] : '') . '.swf';
    $url['myspace']     = 'http://mediaservices.myspace.com/services/media/embed.aspx/m=%1$s';
    $url['revver']      = 'http://flash.revver.com/player/1.0/player.swf?mediaId=%1$u';
    $url['sevenload']   = 'http://en.sevenload.com/pl/%1$s/%2$ux%3$u/swf';
    $url['viddler']     = 'http://www.viddler.com/player/%1$s';
    $url['vimeo']       = 'http://www.vimeo.com/moogaloop.swf?clip_id=%1$d&amp;server=www.vimeo.com&amp;fullscreen=1&amp;show_title=1&amp;show_byline=0&amp;show_portrait=0';
    $url['youku']       = 'http://player.youku.com/player.php/sid/%1$s/.swf';
    $url['youtube']     = 'http://www.youtube.com/v/%1$s?fs=%5$u';


    $flashvars = array();
    $flashvars['revver'] = 'mediaId=%1$u&affiliateId=0';

    $type       = isset($args['type'],$url[$args['type']]) ? $args['type'] : 'youtube';
    $media_url  = isset($url[$type]) ? $url[$type] : $url['youtube'];
    $flash_vars = isset($flashvars[$type]) ? $flashvars[$type] : '';

    $input_array = explode('|', htmlspecialchars($input));
    $id     = current($input_array);
    $width  = (count($input_array) > 1 && is_numeric($input_array[1])) ?     $input_array[1] : 425;
    $height = (count($input_array) > 2 && is_numeric($input_array[2])) ? $input_array[2] : 350;
    $fullscreen = (isset($args['fullscreen']) ? $args['fullscreen'] : 'true') === 'false' ? false : true;

    if(strtolower($type) == 'html5')
    {
        $output = '<video src="'.$id.'" controls style="width:'.$width.'px;height:'.$height.'px"></video><p style="font-size:80%;padding:0;margin:0;">(Right click to control movie)</p>';
        return $output;
    }
    else
    {
        $output = '<object width="%2$u" height="%3$u">'
            .' <param name="movie" value="'.$url[$type].'" />'
            .' <param name="allowFullScreen" value="%4$s" />'
            .' <param name="wmode" value="transparent" />'
            .' <embed src="'.$url[$type] . '" type="application/x-shockwave-flash" wmode="transparent"'
            .' width="%2$u" height="%3$u" allowfullscreen="%4$s"'
                    . ' flashvars="' . $flash_vars . '"></embed></object>';
        return sprintf($output,$id,$width,$height,$fullscreen ? 'true' : 'false', (integer)$fullscreen);
    }
}
?>
