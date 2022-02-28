import Cake.LevelSpecific.Tree.BeetleRiding.TreeBeetleRidingComponent;
import Cake.LevelSpecific.Tree.BeetleRiding.TreeBeetleRidingBeetle;
import Peanuts.Outlines.Outlines;

class UTreeBeetleRidingCapability : UHazeCapability
{
	default CapabilityDebugCategory = n"BeetleRiding";

	default CapabilityTags.Add(n"BeetleRiding");

	default TickGroup = ECapabilityTickGroups::BeforeMovement;

	UTreeBeetleRidingComponent BeetleRidingComponent;
	AHazePlayerCharacter Player;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		BeetleRidingComponent = UTreeBeetleRidingComponent::GetOrCreate(Player);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(BeetleRidingComponent.Beetle == nullptr)
			return EHazeNetworkActivation::DontActivate;

		if(!BeetleRidingComponent.bIsOnBeetle)
			return EHazeNetworkActivation::DontActivate;	

		return EHazeNetworkActivation::ActivateUsingCrumb;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(BeetleRidingComponent.Beetle == nullptr)
			return EHazeNetworkDeactivation::DeactivateLocal;

		if(BeetleRidingComponent.bIsOnBeetle)
			return EHazeNetworkDeactivation::DontDeactivate;

		return EHazeNetworkDeactivation::DeactivateUsingCrumb;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		Player.TriggerMovementTransition(this);

		if(Player.IsMay())
		{
			Player.AttachToComponent(BeetleRidingComponent.Beetle.MayPosition);
			Player.AddLocomotionAsset(BeetleRidingComponent.LocomotionAssetMay, this);
			BeetleRidingComponent.Beetle.bIsMayOn = true;
		}
		else
		{
			Player.AttachToComponent(BeetleRidingComponent.Beetle.CodyPosition);
			Player.AddLocomotionAsset(BeetleRidingComponent.LocomotionAssetCody, this);
			BeetleRidingComponent.Beetle.bIsCodyOn = true;
		}

		Player.BlockCapabilities(n"WeaponAim", this);
		Player.BlockCapabilities(n"Interaction", this);
		Player.BlockCapabilities(n"Movement", this);
		Player.BlockCapabilities(n"CollisionAndOverlap", this);

		Player.DisableOutlineByInstigator(this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		if (BeetleRidingComponent.Beetle != nullptr)
			if(Player.IsMay())
			{
				BeetleRidingComponent.Beetle.bIsMayOn = false;
			}
			else
			{
				BeetleRidingComponent.Beetle.bIsCodyOn = false;
			}

		Player.DetachFromActor(EDetachmentRule::KeepWorld);
		Player.ClearLocomotionAssetByInstigator(this);

		Player.UnblockCapabilities(n"WeaponAim", this);
		Player.UnblockCapabilities(n"Interaction", this);
		Player.UnblockCapabilities(n"Movement", this);
		Player.UnblockCapabilities(n"CollisionAndOverlap", this);

		Player.EnableOutlineByInstigator(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FHazeRequestLocomotionData LocomotionData;
		LocomotionData.AnimationTag = n"BeetleRiding";
		Player.RequestLocomotion(LocomotionData);
	}
}