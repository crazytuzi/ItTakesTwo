import Cake.LevelSpecific.PlayRoom.SpaceStation.SpacePortalComponent;
import Cake.LevelSpecific.PlayRoom.SpaceStation.SpacePortal.SpacePortalExitPoint;

class USpacePortalExitCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::LevelSpecific);

	default CapabilityDebugCategory = n"LevelSpecific";
	
	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 100;

	AHazePlayerCharacter Player;
	USpacePortalComponent SpacePortalComp;
	ASpacePortalExitPoint ExitPoint;

	bool bPortalFullyLeft = false;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		SpacePortalComp = USpacePortalComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (IsActioning(n"ExitSpacePortal"))
        	return EHazeNetworkActivation::ActivateLocal;
        
        return EHazeNetworkActivation::DontActivate;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (bPortalFullyLeft)
			return EHazeNetworkDeactivation::DeactivateLocal;
		
		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		bPortalFullyLeft = false;

		Player.SetCapabilityActionState(n"ExitSpacePortal", EHazeActionState::Inactive);
		
		ExitPoint = Cast<ASpacePortalExitPoint>(GetAttributeObject(n"ExitPoint"));

		float SideMultiplier = Player.IsMay() ? -50.f : 50.f;
		FVector Loc = ExitPoint.Direction.WorldLocation + (ExitPoint.Direction.RightVector * SideMultiplier);
		Player.TeleportActor(Loc, ExitPoint.Direction.WorldRotation);
		
		Player.SnapCameraBehindPlayer();

		FHazeAnimationDelegate AnimFinishedDelegate;
		AnimFinishedDelegate.BindUFunction(this, n"AnimFinished");
		UAnimSequence Anim = Player.IsMay() ? SpacePortalComp.MayExitAnim : SpacePortalComp.CodyExitAnim;
		Player.PlayEventAnimation(OnBlendingOut = AnimFinishedDelegate, Animation = Anim);

		Player.ApplyPivotOffset(FVector::ZeroVector, FHazeCameraBlendSettings(0.f), this);
		Player.ApplyCameraOffsetOwnerSpace(FVector(0.f, 0.f, 0.f), FHazeCameraBlendSettings(0.f), this);
		Player.SnapCameraBehindPlayer(FRotator::ZeroRotator);

		Player.ClearCameraOffsetOwnerSpaceByInstigator(this, 2.f);
		Player.ClearPivotOffsetByInstigator(this, 2.f);

		SpacePortalComp.ExitPortal();

		if (Player.IsCody())
			Player.BlockCapabilities(n"ChangeSize", this);

		Player.PlayForceFeedback(SpacePortalComp.ExitRumble, false, true, n"PortalExit");
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		if (Player.IsCody())
			Player.UnblockCapabilities(n"ChangeSize", this);
	}

	UFUNCTION()
	void AnimFinished()
	{
		bPortalFullyLeft = true;

		if (!SpacePortalComp.bPlayExitBark)
			return;
		
		if (Player.IsMay())
			SpacePortalComp.VOBank.PlayFoghornVOBankEvent(n"FoghornDBPlayRoomSpaceStationFirstPortalExitMay");
		else
			SpacePortalComp.VOBank.PlayFoghornVOBankEvent(n"FoghornDBPlayRoomSpaceStationFirstPortalExitCody");

		SpacePortalComp.bPlayExitBark = false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	

	}
}