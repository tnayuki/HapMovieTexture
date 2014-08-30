using UnityEngine;
using System;
using System.Runtime.InteropServices;

public class HapMovieTexture : MonoBehaviour
{
	public string path;
	public Material movieMaterial;

	private float deltaTimeAfterLastFrame;

#if UNITY_STANDALONE_OSX || UNITY_EDITOR_OSX
	[DllImport ("HapMovieTexturePlugin")]
	private static extern IntPtr CreateContext (string path);
	
	[DllImport ("HapMovieTexturePlugin")]
	private static extern void UpdateTexture (IntPtr context, int textureHandle);

	[DllImport ("HapMovieTexturePlugin")]
	public static extern void DestroyContext (IntPtr context);
	
	private IntPtr context;

	void Start()
	{
		context = CreateContext (System.IO.Path.Combine(Application.streamingAssetsPath, path));	
	}

	void Update ()
	{
		if (movieMaterial != null) {
			/*if ((deltaTimeAfterLastFrame += Time.deltaTime) >= 1.0f / 30.0f) */{
				movieMaterial.mainTexture = new Texture2D(1, 1);
				UpdateTexture(context, movieMaterial.mainTexture.GetNativeTextureID());

				deltaTimeAfterLastFrame = 0;
			}

			Debug.Log (deltaTimeAfterLastFrame);
		}
	}

	void OnDestroy()
	{
		DestroyContext (context);
	}
#else
#endif
}
