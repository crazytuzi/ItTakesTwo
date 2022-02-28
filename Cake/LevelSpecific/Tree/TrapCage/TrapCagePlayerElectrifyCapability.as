import Vino.Movement.Capabilities.Standard.CharacterMovementCapability;
import Cake.LevelSpecific.Tree.TrapCage.TrapCagePlayerComponent;


class UTrapCagePlayerElectrifyCapability : UCharacterMovementCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);

	default TickGroup = ECapabilityTickGroups::BeforeMovement;
	default TickGroupOrder = 2;

	const int ActivationCountBeforeDeath = 3;

	AHazePlayerCharacter Player;
	UTrapCagePlayerComponent TrapComponent;
	float MaxActiveTime = 0;
	FVector TargetPlayerLocation;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Super::Setup(SetupParams);
		Player = Cast<AHazePlayerCharacter>(CharacterOwner);
		TrapComponent = UTrapCagePlayerComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(!MoveComp.CanCalculateMovement())
			return EHazeNetworkActivation::DontActivate;

		if(TrapComponent.TrapState != ETrapStage::Electify)
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(TrapComponent.TrapState != ETrapStage::Electify)
			return EHazeNetworkDeactivation::DeactivateLocal;

		if(ActiveDuration >= MaxActiveTime)
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		SetMutuallyExclusive(CapabilityTags::Movement, true);
		Player.BlockCapabilities(CapabilityTags::GameplayAction, this);
		Player.BlockCapabilities(CapabilityTags::MovementAction, this);

		Player.TriggerMovementTransition(this);
		Player.BlockMovementSyncronization(this);

		Player.PlaySlotAnimation(TrapComponent.Electrify);

		UpdateEffectsLocation();
		TrapComponent.TrapCage.ElectricEffectTop.Activate(true);
		TrapComponent.TrapCage.ElectricEffectBottom.Activate(true);

		TargetPlayerLocation = Player.GetActorLocation();
		if(TrapComponent.TrapCage.ElectrifyCount < ActivationCountBeforeDeath)
		{
			const float Alpha = FMath::Min(float(TrapComponent.TrapCage.ElectrifyCount) / float(ActivationCountBeforeDeath), 1.f);
			MaxActiveTime = FMath::Lerp(0.5f, 2.f, Alpha);
			TargetPlayerLocation.Z = FMath::Max(
				TrapComponent.TrapCage.ElectricEffectBottom.GetWorldLocation().Z + 50.f, 
				TargetPlayerLocation.Z);
		}
		else
		{
			MaxActiveTime = 3.f;
			TargetPlayerLocation.Z = FMath::Max(
				TrapComponent.TrapCage.ElectricEffectBottom.GetWorldLocation().Z + 170.f, 
				TargetPlayerLocation.Z);
		}	
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		SetMutuallyExclusive(CapabilityTags::Movement, false);
		Player.UnblockCapabilities(CapabilityTags::GameplayAction, this);
		Player.UnblockCapabilities(CapabilityTags::MovementAction, this);

		Player.UnblockMovementSyncronization(this);
		Player.RemoveLocomotionFeature(TrapComponent.FreeFlyAsset);

		Player.StopAllSlotAnimations();

		auto Cage = TrapComponent.TrapCage;
		if(Cage != nullptr)
		{
			const bool bKillPlayer = TrapComponent.TrapCage.ElectrifyCount >= ActivationCountBeforeDeath;
			Cage.StopElectrify(bKillPlayer);
		}
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FHazeFrameMovement FinalMovement = MoveComp.MakeFrameMovement(n"Electrify");
		FinalMovement.OverrideStepDownHeight(0.f);

		FVector TargetLocation = FMath::VInterpTo(Player.GetActorLocation(), TargetPlayerLocation, DeltaTime, 5.f);
		FVector Delta = TargetLocation - Player.GetActorLocation();
		PrintToScreen("Delta: " + Delta);
		FinalMovement.ApplyDelta(Delta);

		MoveCharacter(FinalMovement, NAME_None);
		UpdateEffectsLocation();
	}

	void UpdateEffectsLocation()
	{
		// Top
		FVector TopLocation = Player.GetActorLocation();
		TopLocation.Z += Player.GetCollisionSize().Y;
		TrapComponent.TrapCage.ElectricEffectTop.SetWorldLocation(TopLocation);
		
		// Bottom
		FVector BottomLocation = Player.GetActorLocation();
		const float BeamHeight = TrapComponent.TrapCage.ElectricEffectBottom.GetWorldLocation().Z;
		const float BeamEffectHeight = BottomLocation.Z - BeamHeight;
		BottomLocation.Z = BeamHeight;
		TrapComponent.TrapCage.ElectricEffectBottom.SetNiagaraVariableVec3("BeamPlace", FVector(300.f, 0.f, 0.f));
		TrapComponent.TrapCage.ElectricEffectBottom.SetWorldLocation(BottomLocation);
	}
}