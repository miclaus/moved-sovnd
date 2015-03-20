# MOVED SOVND
Interactive experimental installation generating "semi-binaural-beats" using the Kinect - made with Processing.

### Background Clip
The current clip file is just a sample. 

Replace *data/the-clip.mp4* with your own clip.

### Snapshots
If you want to take snapshots, change the constant:
```
final String takeSnapshots = true;
```

Set the absolute path where your snapshots should be saved at, by changing the constant:
```
final String savePath = "/path/to/snapshots/directory";
```

### Social Feed
If you want to activate the facebook social feed of a public post, change the constant:
```
final String requestOnlinePosts = true;
```

Set the facebook post ID in order to request the corresponding comments:
```
final String POST_ID = "FB_GRAPH_PUBLIC_POST_ID";
```
