import Vino.Movement.Components.MovementComponent;
import Cake.LevelSpecific.Tree.Boat.TreeBoatComponent;

class UTreeBoatImpactCapability : UHazeCapability
{
	default CapabilityTags.Add(n"TreeBoat");

	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 100;

	AHazePlayerCharacter Player;
	UHazeMovementComponent MoveComp;
	UTreeBoatComponent TreeBoatComponent;

	float KnockDownTimer = 0.f;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		MoveComp = UHazeMovementComponent::Get(Owner);
		TreeBoatComponent = UTreeBoatComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
//		if(!System::IsValid(TreeBoatComponent.ActiveTreeBoat))
//			return EHazeNetworkActivation::DontActivate;

		if(TreeBoatComponent.ActiveTreeBoat == nullptr)
			return EHazeNetworkActivation::DontActivate;

		if(!TreeBoatComponent.bIsKnockedDown)
			return EHazeNetworkActivation::DontActivate;	

		return EHazeNetworkActivation::ActivateUsingCrumb;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
//		if(!System::IsValid(TreeBoatComponent.ActiveTreeBoat))
//			return EHazeNetworkDeactivation::DeactivateLocal;

		if(TreeBoatComponent.ActiveTreeBoat == nullptr)
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		if(!TreeBoatComponent.bIsKnockedDown)
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		Player.PlaySlotAnimation(Animation = (Player.IsMay() ? TreeBoatComponent.MayImpactAnimation : TreeBoatComponent.CodyImpactAnimation));
		KnockDownTimer = TreeBoatComponent.ImpactDuration;
		Player.BlockCapabilities(CapabilityTags::MovementInput, this);
		Player.BlockCapabilities(SapWeaponTags::Aim, this);
		Player.BlockCapabilities(n"MatchWeaponAim", this);
		Player.BlockCapabilities(n"TreeBoatThrottle", this);	
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		TreeBoatComponent.bIsKnockedDown = false;
		Player.UnblockCapabilities(CapabilityTags::MovementInput, this);
		Player.UnblockCapabilities(SapWeaponTags::Aim, this);
		Player.UnblockCapabilities(n"MatchWeaponAim", this);
		Player.UnblockCapabilities(n"TreeBoatThrottle", this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		KnockDownTimer -= DeltaTime;
		
		if (KnockDownTimer <= 0)
		{
			TreeBoatComponent.bIsKnockedDown = false;
		}	
	}

}