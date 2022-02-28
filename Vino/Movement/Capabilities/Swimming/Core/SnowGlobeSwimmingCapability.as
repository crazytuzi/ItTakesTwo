import Vino.Movement.Capabilities.Swimming.SnowGlobeSwimmingComponent;
import Vino.Movement.Components.MovementComponent;

class USnowGlobeSwimmingCapability : UHazeCapability
{
	default CapabilityTags.Add(MovementSystemTags::Swimming);

	default CapabilityDebugCategory = n"Movement Swimming";
	
	default TickGroup = ECapabilityTickGroups::BeforeMovement;
	default TickGroupOrder = 20;

	AHazePlayerCharacter Player;
	USnowGlobeSwimmingComponent SwimComp; 
	UHazeMovementComponent MoveComp;

	UNiagaraComponent BubbleNiagaraComp;
	UNiagaraComponent LeftHandTrailNiagaraComp;
	UNiagaraComponent RightHandTrailNiagaraComp;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		SwimComp = USnowGlobeSwimmingComponent::GetOrCreate(Player);
		MoveComp = UHazeMovementComponent::GetOrCreate(Player);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if ((SwimComp.bIsInWater || SwimComp.SwimmingState != ESwimmingState::Inactive))
			return EHazeNetworkActivation::ActivateUsingCrumb;

		if (IsActioning(n"AllowDive"))
			return EHazeNetworkActivation::ActivateUsingCrumb;

        return EHazeNetworkActivation::DontActivate;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(!SwimComp.bIsInWater && (SwimComp.SwimmingState == ESwimmingState::Inactive))
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{	
		SwimComp.AddFeature(Player);

		if (SwimComp.BubblesFX != nullptr)
		{
			if (BubbleNiagaraComp == nullptr)
				BubbleNiagaraComp = Niagara::SpawnSystemAttached(SwimComp.BubblesFX, Player.Mesh, n"Root", FVector::ZeroVector, FRotator::ZeroRotator, EAttachLocation::SnapToTarget, false);
			else
				BubbleNiagaraComp.Activate();
				
		}

		if (SwimComp.TrailsFX != nullptr)
		{
			if (LeftHandTrailNiagaraComp == nullptr)
				LeftHandTrailNiagaraComp = Niagara::SpawnSystemAttached(SwimComp.TrailsFX, Player.Mesh, n"LeftHand", FVector::ZeroVector, FRotator::ZeroRotator, EAttachLocation::SnapToTarget, false);
			else
				LeftHandTrailNiagaraComp.Activate();

			if (RightHandTrailNiagaraComp == nullptr)
				RightHandTrailNiagaraComp = Niagara::SpawnSystemAttached(SwimComp.TrailsFX, Player.Mesh, n"RightHand", FVector::ZeroVector, FRotator::ZeroRotator, EAttachLocation::SnapToTarget, false);
			else
				RightHandTrailNiagaraComp.Activate();
		}

		Owner.BlockCapabilities(n"CannonShoot", this);
		Owner.BlockCapabilities(MovementSystemTags::GroundPound, this);
		Owner.BlockCapabilities(ActionNames::WeaponAim, this);
		Owner.BlockCapabilities(MovementSystemTags::SlopeSlide, this);
		Owner.BlockCapabilities(MovementSystemTags::SplineSlide, this);
		Owner.BlockCapabilities(n"Sliding", this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		SwimComp.RemoveFeature(Player);

		Owner.UnblockCapabilities(n"CannonShoot", this);
		Owner.UnblockCapabilities(MovementSystemTags::GroundPound, this);
		Owner.UnblockCapabilities(ActionNames::WeaponAim, this);
		Owner.UnblockCapabilities(MovementSystemTags::SlopeSlide, this);
		Owner.UnblockCapabilities(MovementSystemTags::SplineSlide, this);
		Owner.UnblockCapabilities(n"Sliding", this);

		Player.Mesh.SetRelativeRotation(FRotator::ZeroRotator);

		if (BubbleNiagaraComp != nullptr)
			BubbleNiagaraComp.Deactivate();

		if (LeftHandTrailNiagaraComp != nullptr)
			LeftHandTrailNiagaraComp.Deactivate();

		if (RightHandTrailNiagaraComp != nullptr)
			RightHandTrailNiagaraComp.Deactivate();
			
		SwimComp.SwimmingState = ESwimmingState::Inactive;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		if (MoveComp.IsGrounded() && !SwimComp.bIsInWater)
		{
			SwimComp.SwimmingState = ESwimmingState::Inactive;
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnRemoved()
	{
		if (BubbleNiagaraComp != nullptr)
			BubbleNiagaraComp.DestroyComponent(Player);

		if (LeftHandTrailNiagaraComp != nullptr)
			LeftHandTrailNiagaraComp.DestroyComponent(Player);

		if (RightHandTrailNiagaraComp != nullptr)
			RightHandTrailNiagaraComp.DestroyComponent(Player);

		SwimComp.SwimmingState = ESwimmingState::Inactive;
	}
}
