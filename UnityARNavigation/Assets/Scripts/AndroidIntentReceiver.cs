using UnityEngine;
using System.Collections.Generic;

#if UNITY_ANDROID
using UnityEngine.Android;
#endif

/// <summary>
/// Receives Android Intent data from the Flutter app and initializes navigation
/// </summary>
public class AndroidIntentReceiver : MonoBehaviour
{
    [Header("Navigation Components")]
    [SerializeField] private NavigationManager navigationManager;
    [SerializeField] private WaypointSystem waypointSystem;
    
    [Header("UI Components")]
    [SerializeField] private GameObject destinationInfoPanel;
    [SerializeField] private TMPro.TextMeshProUGUI destinationText;
    [SerializeField] private TMPro.TextMeshProUGUI buildingText;
    [SerializeField] private TMPro.TextMeshProUGUI roomText;
    
    [Header("Debug")]
    [SerializeField] private bool useDebugData = false;
    [SerializeField] private string debugBuildingName = "Library";
    [SerializeField] private string debugRoomName = "Reading Hall";
    
    private NavigationData _navigationData;
    
    [System.Serializable]
    public class NavigationData
    {
        public string buildingName;
        public string roomName;
        public string destinationLat;
        public string destinationLng;
        public string buildingDescription;
    }
    
    void Start()
    {
        // Request camera permissions
        RequestPermissions();
        
        // Initialize with debug data or wait for intent
        if (useDebugData)
        {
            InitializeWithDebugData();
        }
        else
        {
            // Try to get intent data
            GetIntentData();
        }
    }
    
    void RequestPermissions()
    {
#if UNITY_ANDROID
        if (!Permission.HasUserAuthorizedPermission(Permission.Camera))
        {
            Permission.RequestUserPermission(Permission.Camera);
        }
        
        if (!Permission.HasUserAuthorizedPermission(Permission.FineLocation))
        {
            Permission.RequestUserPermission(Permission.FineLocation);
        }
#endif
    }
    
    void GetIntentData()
    {
#if UNITY_ANDROID
        try
        {
            // Get the current activity
            AndroidJavaClass unityPlayer = new AndroidJavaClass("com.unity3d.player.UnityPlayer");
            AndroidJavaObject currentActivity = unityPlayer.GetStatic<AndroidJavaObject>("currentActivity");
            
            if (currentActivity != null)
            {
                // Get the intent
                AndroidJavaObject intent = currentActivity.Call<AndroidJavaObject>("getIntent");
                
                if (intent != null)
                {
                    // Extract intent extras
                    _navigationData = new NavigationData();
                    
                    _navigationData.buildingName = GetIntentExtra(intent, "building_name");
                    _navigationData.roomName = GetIntentExtra(intent, "room_name");
                    _navigationData.destinationLat = GetIntentExtra(intent, "destination_lat");
                    _navigationData.destinationLng = GetIntentExtra(intent, "destination_lng");
                    _navigationData.buildingDescription = GetIntentExtra(intent, "building_description");
                    
                    Debug.Log($"Received Intent Data: Building={_navigationData.buildingName}, Room={_navigationData.roomName}");
                    
                    // Initialize navigation
                    InitializeNavigation();
                }
                else
                {
                    Debug.LogWarning("No intent found, using default navigation");
                    InitializeWithDefaultData();
                }
            }
        }
        catch (System.Exception e)
        {
            Debug.LogError($"Error getting intent data: {e.Message}");
            InitializeWithDefaultData();
        }
#endif
    }
    
    string GetIntentExtra(AndroidJavaObject intent, string key)
    {
#if UNITY_ANDROID
        try
        {
            return intent.Call<string>("getStringExtra", key) ?? "";
        }
        catch
        {
            return "";
        }
#else
        return "";
#endif
    }
    
    void InitializeWithDebugData()
    {
        _navigationData = new NavigationData
        {
            buildingName = debugBuildingName,
            roomName = debugRoomName,
            destinationLat = "7.359008",
            destinationLng = "125.706665",
            buildingDescription = "Main campus library with study areas and archives."
        };
        
        InitializeNavigation();
    }
    
    void InitializeWithDefaultData()
    {
        _navigationData = new NavigationData
        {
            buildingName = "Unknown Building",
            roomName = "",
            destinationLat = "0",
            destinationLng = "0",
            buildingDescription = "Default navigation destination."
        };
        
        InitializeNavigation();
    }
    
    void InitializeNavigation()
    {
        if (_navigationData == null)
        {
            Debug.LogError("Navigation data is null!");
            return;
        }
        
        // Update UI
        UpdateDestinationUI();
        
        // Initialize waypoint system
        if (waypointSystem != null)
        {
            waypointSystem.InitializeWaypoints(_navigationData.buildingName);
        }
        
        // Start navigation
        if (navigationManager != null)
        {
            navigationManager.StartNavigation(_navigationData);
        }
        
        // Hide destination info after a delay
        Invoke(nameof(HideDestinationInfo), 5f);
    }
    
    void UpdateDestinationUI()
    {
        if (destinationInfoPanel != null)
        {
            destinationInfoPanel.SetActive(true);
        }
        
        if (destinationText != null)
        {
            destinationText.text = $"Destination: {_navigationData.buildingName}";
        }
        
        if (buildingText != null)
        {
            buildingText.text = _navigationData.buildingDescription;
        }
        
        if (roomText != null && !string.IsNullOrEmpty(_navigationData.roomName))
        {
            roomText.text = $"Room: {_navigationData.roomName}";
        }
    }
    
    void HideDestinationInfo()
    {
        if (destinationInfoPanel != null)
        {
            destinationInfoPanel.SetActive(false);
        }
    }
    
    // Public method to return to Flutter app
    public void ReturnToFlutterApp()
    {
#if UNITY_ANDROID
        try
        {
            AndroidJavaClass unityPlayer = new AndroidJavaClass("com.unity3d.player.UnityPlayer");
            AndroidJavaObject currentActivity = unityPlayer.GetStatic<AndroidJavaObject>("currentActivity");
            
            if (currentActivity != null)
            {
                currentActivity.Call("finish");
            }
        }
        catch (System.Exception e)
        {
            Debug.LogError($"Error returning to Flutter app: {e.Message}");
        }
#endif
    }
    
    // Method to get current navigation data (for other scripts)
    public NavigationData GetNavigationData()
    {
        return _navigationData;
    }
}
