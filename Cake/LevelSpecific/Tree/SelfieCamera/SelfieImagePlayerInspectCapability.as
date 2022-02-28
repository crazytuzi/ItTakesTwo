import Cake.LevelSpecific.Tree.SelfieCamera.SelfieCameraImage;
import Vino.Movement.MovementSystemTags;
import Cake.Weapons.Sap.SapWeaponNames;
import Vino.Camera.Components.CameraUserComponent;
import Cake.LevelSpecific.Tree.SelfieCamera.SelfieCorkBoardActor;
import Cake.LevelSpecific.Tree.SelfieCamera.SelfieImagePlayerInspectComponent;

class USelfieImagePlayerInspectCapability : UHazeCapability
{
	default CapabilityTags.Add(n"SelfieImagePlayerInspectCapability");
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(n"SelfieCamera");

	default CapabilityDebugCategory = n"GamePlay";
	
	default TickGroup = ECapabilityTickGroups::BeforeMovement;
	default TickGroupOrder = 100;

	AHazePlayerCharacter Player;
	UCameraUserComponent UserComp;
	ASelfieCameraImage Image;
	USelfieImagePlayerInspectComponent PlayerInspectComp;
	
	//NEED TO FIND A WAY TO PICK THE RIGHT CAMERA
	TArray<ASelfieCorkBoardActor> SelfieCorkBoardArray;
	ASelfieCorkBoardActor SelfieCorkBoard;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		UserComp = UCameraUserComponent::Get(Player);
		GetAllActorsOfClass(SelfieCorkBoardArray);
		SelfieCorkBoard = SelfieCorkBoardArray[0]; 
		PlayerInspectComp = USelfieImagePlayerInspectComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
        return EHazeNetworkActivation::ActivateUsingCrumb;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (WasActionStarted(ActionNames::Cancel))
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void ControlPreActivation(FCapabilityActivationSyncParams& ActivationParams)
	{
		ActivationParams.AddObject(n"SelfieImage", GetAttributeObject(n"SelfieImage"));
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		Image = Cast<ASelfieCameraImage>(ActivationParams.GetObject(n"SelfieImage"));

		SetMutuallyExclusive(CapabilityTags::GameplayAction, true);

		Player.BlockCapabilities(CapabilityTags::Movement, this);
		Player.BlockCapabilities(CapabilityTags::Input, this);
		Player.BlockCapabilities(ActionNames::WeaponAim, this);

		Player.TriggerMovementTransition(this);

		FHazeCameraBlendSettings Blend;
		Blend.BlendTime = 1.5f;
		Image.TargetCam.ActivateCamera(Player, Blend, this);
		
		PlayerInspectComp.ShowPlayerCancel(Player);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		Player.ConsumeButtonInputsRelatedTo(ActionNames::Cancel);

		SetMutuallyExclusive(CapabilityTags::GameplayAction, false);
		
		Player.UnblockCapabilities(CapabilityTags::Movement, this);
		Player.UnblockCapabilities(CapabilityTags::Input, this);
		Player.UnblockCapabilities(ActionNames::WeaponAim, this);
		
		Image.TargetCam.DeactivateCamera(Player, 1.5f);
		PlayerInspectComp.HidePlayerCancel(Player);

		PlayerInspectComp.OnSelfieImageCancelInspection.Broadcast(Player);
	}
}