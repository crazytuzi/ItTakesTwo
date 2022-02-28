import Vino.Movement.Capabilities.Standard.CharacterMovementCapability;
import Cake.LevelSpecific.Tree.TrapCage.TrapCagePlayerComponent;


class UTrapCagePlayerAcornCapability : UCharacterMovementCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);

	default TickGroup = ECapabilityTickGroups::BeforeMovement;
	default TickGroupOrder = 2;

	AHazePlayerCharacter Player;
	UTrapCagePlayerComponent TrapComponent;
	ATrapCagePlayerActorn ActornActor;
	UHazeCrumbComponent PlayerCrumb;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Super::Setup(SetupParams);
		Player = Cast<AHazePlayerCharacter>(CharacterOwner);
		PlayerCrumb = UHazeCrumbComponent::Get(Player);
		TrapComponent = UTrapCagePlayerComponent::Get(Player);
		ActornActor = Cast<ATrapCagePlayerActorn>(SpawnActor(TrapComponent.ActornType, Level = Player.GetLevel()));
	}

	UFUNCTION(BlueprintOverride)
	void OnRemoved()
	{
		if(ActornActor != nullptr)
		{
			ActornActor.DestroyActor();
			ActornActor = nullptr;
		}
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(!MoveComp.CanCalculateMovement())
			return EHazeNetworkActivation::DontActivate;

		if(TrapComponent.TrapState != ETrapStage::AcornCrusher)
			return EHazeNetworkActivation::DontActivate;

		if(TrapComponent.TrapCage.bActornCrusherHasCrushed)
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(TrapComponent.TrapState != ETrapStage::AcornCrusher)
			return EHazeNetworkDeactivation::DeactivateLocal;

		if(TrapComponent.TrapCage.bActornCrusherHasCrushed)
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		SetMutuallyExclusive(CapabilityTags::Movement, true);
		Player.SetActorHiddenInGame(true);
		Player.BlockCapabilities(CapabilityTags::GameplayAction, this);
		Player.BlockCapabilities(CapabilityTags::MovementAction, this);
		ActornActor.EnableActor(nullptr);
		ActornActor.SetActorLocation(Player.GetActorLocation());
		ActornActor.Root.AddImpulse(FVector::UpVector * 10000);
		ActornActor.Root.AddImpulse(FRotator(0.f, FMath::RandRange(0, 360), 0.f).Vector() * 10000);
		PlayerCrumb.IncludeCustomParamsInActorReplication(FVector::ZeroVector, FRotator::ZeroRotator, this);
		ActornActor.Root.SetSimulatePhysics(HasControl());

		Player.CleanupCurrentMovementTrail();
		Player.SetActorLocation(TrapComponent.TrapCage.AcornRespawn.GetWorldLocation());
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		SetMutuallyExclusive(CapabilityTags::Movement, false);
		Player.SetActorHiddenInGame(false);
		Player.UnblockCapabilities(CapabilityTags::GameplayAction, this);
		Player.UnblockCapabilities(CapabilityTags::MovementAction, this);

		Niagara::SpawnSystemAtLocation(ActornActor.ActornExplosion, ActornActor.GetActorLocation());
		ActornActor.DisableActor(nullptr);
		PlayerCrumb.RemoveCustomParamsFromActorReplication(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(HasControl())
		{
			const FVector SteeringVector = GetAttributeVector(AttributeVectorNames::MovementDirection);
			ActornActor.Root.AddImpulse(SteeringVector * 5000);
			CrumbComp.CustomCrumbVector = ActornActor.GetActorLocation();
			CrumbComp.CustomCrumbRotation = ActornActor.GetActorRotation();
			CrumbComp.LeaveMovementCrumb();
		}
		else
		{
			FHazeActorReplicationFinalized CrumbMovement;
			CrumbComp.ConsumeCrumbTrailMovement(DeltaTime, CrumbMovement);
			ActornActor.SetActorLocationAndRotation(CrumbMovement.CustomCrumbVector, CrumbMovement.CustomCrumbRotator);
		}
		
		FHazeFrameMovement FinalMovement = MoveComp.MakeFrameMovement(n"AcornMovement");
		MoveCharacter(FinalMovement, n"Movement");
	}
}