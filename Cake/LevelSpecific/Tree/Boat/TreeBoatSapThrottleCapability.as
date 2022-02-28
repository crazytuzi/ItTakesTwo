import Vino.Movement.Capabilities.Standard.CharacterMovementCapability;
import Cake.LevelSpecific.Tree.Boat.TreeBoatComponent;
import Cake.Weapons.Sap.SapWeaponWielderComponent;
import Peanuts.Movement.DeltaProcessor;

class USapThrottleDeltaProcessor : UDeltaProcessor
{
	AActor LockToActor;

	float MaxDistance = 742.f;

	FVector Derp(FVector CurrentLocation, FVector WantedDelta)
	{
		FVector WantedLocation = CurrentLocation + WantedDelta;
		FVector FromPointVector = (WantedLocation - LockToActor.GetActorLocation());

		FVector NewWantedLocation = LockToActor.GetActorLocation() + FromPointVector.GetSafeNormal() * MaxDistance;
		FVector NewDelta = NewWantedLocation - CurrentLocation;
		return NewDelta;
	}

	void PreIteration(FCollisionSolverActorState ActorState, FCollisionSolverState& SolverState, float IterationTimeStep) override
	{
		SolverState.RemainingDelta = Derp(SolverState.CurrentLocation, SolverState.RemainingDelta);
	}
}

class UTreeBoatSapThrottleCapability : UCharacterMovementCapability
{
	default CapabilityTags.Add(n"TreeBoat");
	default CapabilityTags.Add(n"TreeBoatThrottle");
	default CapabilityTags.Add(n"TreeBoatThrottleShoot");
	default CapabilityTags.Add(CapabilityTags::Weapon);
	default CapabilityTags.Add(SapWeaponTags::Weapon);

	default TickGroup = ECapabilityTickGroups::BeforeMovement;

	default TickGroupOrder = 100;

	AHazePlayerCharacter Player;

	UTreeBoatComponent TreeBoatComponent;
	USapWeaponWielderComponent SapWeaponWielderComponent;

	UNiagaraComponent SapNiagaraSystem;
	
	USapThrottleDeltaProcessor DeltaProcessor;

	float EffectInterval = 0.f;

	float VFXDelay = 0.3f;
	float VFXDelayTimer = 0.f;

	FHazePointOfInterest POI;
	ASapWeapon Weapon;

	UFUNCTION(BlueprintOverride)
	void Setup(const FCapabilitySetupParams& SetupParams)
	{
		Super::Setup(SetupParams);

		Player = Cast<AHazePlayerCharacter>(Owner);
		TreeBoatComponent = UTreeBoatComponent::Get(Owner);

		DeltaProcessor = USapThrottleDeltaProcessor();

		EffectInterval = TreeBoatComponent.SapEffectInterval;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
//		if(!System::IsValid(TreeBoatComponent.ActiveTreeBoat))
//			return EHazeNetworkActivation::DontActivate;

		if(TreeBoatComponent.ActiveTreeBoat == nullptr)
			return EHazeNetworkActivation::DontActivate;

		if(Player.IsAnyCapabilityActive(SapWeaponTags::Aim))
			return EHazeNetworkActivation::DontActivate;

		if(!WasActionStarted(ActionNames::PrimaryLevelAbility))
			return EHazeNetworkActivation::DontActivate;

		if(!Player.IsCody())
			return EHazeNetworkActivation::DontActivate;

		if(!TreeBoatComponent.bInSapThrottleRange)
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateUsingCrumb;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
//		if(!System::IsValid(TreeBoatComponent.ActiveTreeBoat))
//			return EHazeNetworkDeactivation::DeactivateLocal;

		if (Weapon == nullptr)
			return EHazeNetworkDeactivation::DeactivateLocal;

		if(TreeBoatComponent.ActiveTreeBoat == nullptr)
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		if(!IsActioning(ActionNames::PrimaryLevelAbility))
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;


		// Should never happen
//		if(!TreeBoatComponent.bInSapThrottleRange)
//			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{

//		Player.PlayBlendSpace(TreeBoatComponent.SapThrottleBlendSpace);

		SapWeaponWielderComponent = USapWeaponWielderComponent::Get(Owner);
		Weapon = SapWeaponWielderComponent.Weapon;

		Player.BlockCapabilities(n"TreeBoatThrottleWidget", this);
		Player.BlockCapabilities(n"TreeBoatConstrain", this);
		Player.BlockCapabilities(SapWeaponTags::Aim, this);
		Player.BlockCapabilities(CapabilityTags::CharacterFacing, this);
		Player.BlockCapabilities(CapabilityTags::MovementAction, this);
		Player.BlockCapabilities(MovementSystemTags::Sprint, this);

		POI.FocusTarget.Actor = Player;
		POI.FocusTarget.LocalOffset = FVector::ForwardVector * -1000.f;
		POI.Blend.BlendTime = 0.5f;

		Player.ApplyClampedPointOfInterest(POI, this);

		MoveComp.UseDeltaProcessor(DeltaProcessor, this);
		DeltaProcessor.LockToActor = TreeBoatComponent.ActiveTreeBoat;

		SapNiagaraSystem = UNiagaraComponent::GetOrCreate(Owner);
		SapNiagaraSystem.SetAsset(TreeBoatComponent.SapThrottleParticleSystem);
		SapNiagaraSystem.AttachToComponent(Weapon.Mesh, n"SapSpawn", EAttachmentRule::SnapToTarget);
		SapNiagaraSystem.SetNiagaraVariableFloat("SpawnRate", 0.f);
		SapNiagaraSystem.Activate();

		Weapon.BP_StartUnderWaterShot();
	
		Player.AddLocomotionFeature(TreeBoatComponent.TreeBoatSteeringFeature_Cody);

		VFXDelayTimer = VFXDelay;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		Player.UnblockCapabilities(n"TreeBoatThrottleWidget", this);
		Player.UnblockCapabilities(n"TreeBoatConstrain", this);
		Player.UnblockCapabilities(SapWeaponTags::Aim, this);
		Player.UnblockCapabilities(CapabilityTags::CharacterFacing, this);
		Player.UnblockCapabilities(CapabilityTags::MovementAction, this);
		Player.UnblockCapabilities(MovementSystemTags::Sprint, this);

//		Player.StopBlendSpace();

		Player.ClearPointOfInterestByInstigator(this);

		MoveComp.StopDeltaProcessor(this);

		SapNiagaraSystem.Deactivate();
		Weapon.BP_StopUnderWaterShot();
		Weapon = nullptr;
	
		Player.RemoveLocomotionFeature(TreeBoatComponent.TreeBoatSteeringFeature_Cody);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FVector Direction = Player.GetActorLocation() - TreeBoatComponent.ActiveTreeBoat.GetActorLocation();
		Direction.Normalize();

//		TreeBoatComponent.ActiveTreeBoat.AddSapThrust(Direction);

		FVector StrafeDirection = Direction.CrossProduct(TreeBoatComponent.ActiveTreeBoat.RotationPivot.GetUpVector());
		FVector MovementDirection = GetAttributeVector(AttributeVectorNames::MovementDirection);

//		Player.SetBlendSpaceValues(StrafeDirection.DotProduct(MovementDirection), 0.f);
		MoveComp.SetTargetFacingRotation(Direction.Rotation());

		FHazeRequestLocomotionData AnimRequest;
		AnimRequest.AnimationTag = n"SapBoat";
		AnimRequest.WantedVelocity = StrafeDirection.DotProduct(MovementDirection);
		Player.RequestLocomotion(AnimRequest);

		if (VFXDelayTimer > 0.f)
		{
			VFXDelayTimer -= DeltaTime;
		}
		else
		{
			SapNiagaraSystem.SetNiagaraVariableFloat("SpawnRate", 50.0f);
			TreeBoatComponent.ActiveTreeBoat.AddSapThrust(Direction);
		}
	}
	
}
