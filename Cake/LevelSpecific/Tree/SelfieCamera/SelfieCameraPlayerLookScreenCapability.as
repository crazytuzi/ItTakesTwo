import Cake.LevelSpecific.Tree.SelfieCamera.SelfieCameraWidget;
import Cake.LevelSpecific.Tree.SelfieCamera.SelfieCameraActor;
import Cake.LevelSpecific.Tree.SelfieCamera.SelfieCameraPlayerComponent;

class USelfieCameraPlayerLookScreenCapability : UHazeCapability
{
	default CapabilityTags.Add(n"SelfieCameraPlayerLookScreenCapability");
	default CapabilityTags.Add(n"SelfieCamera");

	default CapabilityDebugCategory = n"GamePlay";
	
	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 100;

	AHazePlayerCharacter Player;

	ASelfieCameraActor SelfieCamActor;

	USelfieCameraPlayerComponent PlayerComp;

	float CurrentShowWidgetsTime;
	float DefaultShowWidgetsTime = 0.75f;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		SelfieCamActor = GetSelfieCameraActor();
		PlayerComp = USelfieCameraPlayerComponent::Get(Player);
		CurrentShowWidgetsTime = DefaultShowWidgetsTime;

		SelfieCamActor.bCanTakePicture = false;
		PlayerComp.bCanCancel = false;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
        return EHazeNetworkActivation::ActivateUsingCrumb;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnRemoved()
	{
		Player.RemoveWidget(PlayerComp.WidgetRef);
    }

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		if (CurrentShowWidgetsTime > 0.f)
		{
			CurrentShowWidgetsTime -= DeltaTime;

			if (CurrentShowWidgetsTime <= 0.f && HasControl())
				NetActivateScreens();
		}
	}

	UFUNCTION(NetFunction)
	void NetActivateScreens()
	{
		SelfieCamActor.bCanTakePicture = true;
		PlayerComp.ShowPlayerTakePic(Player);
		PlayerComp.bCanCancel = true;
		PlayerComp.ShowPlayerCancel(Player);
		PlayerComp.WidgetRef = Cast<USelfieCameraWidget>(Player.AddWidget(SelfieCamActor.Widget));
		PlayerComp.WidgetRef.SetWidgetZOrderInLayer(-20);
	}
}