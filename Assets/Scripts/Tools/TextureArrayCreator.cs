using UnityEngine;
using UnityEditor;
using UnityEditorInternal;

using System.Collections.Generic;
using System.IO;

namespace Tools
{
    public class TextureArrayCreator : ScriptableWizard
    {
        [MenuItem("Window/Custom Tools/Texture Array Creator")]
        public static void ShowWindow()
        {
            ScriptableWizard.DisplayWizard<TextureArrayCreator>("Create Texture Array", "Build Asset");
        }

        public string saveFolder = "Assets/Textures/";

        public string fileName = "MyTextureArray";

        public List<Texture2D> textures = new List<Texture2D>();

        private ReorderableList list;

        void OnWizardCreate()
        {
            CompileTextureArray(textures, saveFolder, fileName);
        }

        private void CompileTextureArray(List<Texture2D> _textures, string _saveFolder, string _fileName)
        {
            if (_textures == null || _textures.Count == 0)
            {
                Debug.LogError("[TextureArrayCreator] No textures assigned.");
                return;
            }

            // the first texture gives the size and format of the texture array, 
            // and all other textures are supposed to share the same properties
            Texture2D firstTex = _textures[0];
            Texture2DArray textureArray = new Texture2DArray(firstTex.width, firstTex.height, _textures.Count, firstTex.format, false);
            textureArray.filterMode = FilterMode.Trilinear;
            textureArray.wrapMode = TextureWrapMode.Repeat;

            // copies the textures in the CPU array
            for (int i = 0; i < _textures.Count; i++)
            {
                Texture2D tex = _textures[i];

                if (tex.width != textureArray.width || tex.height != textureArray.height || tex.format != textureArray.format)
                {
                    Debug.LogWarning("[TextureArrayCreator] Texture n°" + i + " skipped because its size and format are not compatible.");
                    continue;
                }

                textureArray.SetPixels(tex.GetPixels(0), i, 0);
            }

            // uploads the texture array to GPU
            textureArray.Apply();

            // saves the asset on disk
            string uri = Path.Combine(_saveFolder, _fileName) + ".asset";
            AssetDatabase.CreateAsset(textureArray, uri);
            Debug.Log("[TextureArrayCreator] Saved asset to " + uri + ".");
        }
    }
}