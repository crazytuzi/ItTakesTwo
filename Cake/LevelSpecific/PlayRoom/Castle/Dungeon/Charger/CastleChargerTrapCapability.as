import Vino.Movement.Capabilities.Standard.CharacterMovementCapability;
import Cake.LevelSpecific.PlayRoom.Castle.Dungeon.CastleChargerTrap;
import Cake.LevelSpecific.PlayRoom.Castle.CastleEnemyAI.Charger.CastleEnemyChargerComponent;

class UCastleChargerTrapCapability : UCharacterMovementCapability
{	
	default CapabilityTags.Add(n"CastleEnemyAI");
	default CapabilityTags.Add(n"ChargerTrap");
	
	default TickGroup = ECapabilityTickGroups::BeforeMovement;
	default TickGroupOrder = 10;

	default CapabilityDebugCategory = CapabilityTags::Movement;

	ACastleEnemy Charger;
	UCastleEnemyChargerComponent ChargerComp;

	const float TimeToTrap = 0.2f;
	float SpeedToTrap = 0.f;

	const float Duration = 1.f;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Super::Setup(SetupParams);
		Charger = Cast<ACastleEnemy>(Owner);
		ChargerComp = UCastleEnemyChargerComponent::GetOrCreate(Owner);
	}
	
	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (!MoveComp.CanCalculateMovement())
       		return EHazeNetworkActivation::DontActivate;

		if (!ChargerComp.Trap.bActive)
       		return EHazeNetworkActivation::DontActivate;

		if (!IsTrapSuccessful())
			return EHazeNetworkActivation::DontActivate;

        return EHazeNetworkActivation::ActivateUsingCrumb;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (!MoveComp.CanCalculateMovement())
			return RemoteLocalControlCrumbDeactivation();

		if (ActiveDuration >= Duration)
       		return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		Charger.BlockCapabilities(n"Movement", this);
		Charger.BlockCapabilities(n"CastleEnemyAI", this);
		Charger.BlockCapabilities(n"CastleEnemyKnockback", this);
		Charger.BlockCapabilities(n"CastleEnemyCharge", this);

		Charger.CapsuleComponent.SetCollisionEnabled(ECollisionEnabled::NoCollision);
		Charger.bUnhittable = true;

		ChargerComp.Trap.OnChargerTrapped.Broadcast();

		// Should spawn a blocker so you cant fall into the hole

		FVector ToTrap = ChargerComp.Trap.ActorLocation - Charger.ActorLocation;
		SpeedToTrap = ToTrap.Size() / TimeToTrap;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		ChargerComp.bChargerTrapped = true;
		
		Charger.UnblockCapabilities(n"Movement", this);
		Charger.UnblockCapabilities(n"CastleEnemyAI", this);
		Charger.UnblockCapabilities(n"CastleEnemyKnockback", this);
		Charger.UnblockCapabilities(n"CastleEnemyCharge", this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		FHazeFrameMovement FrameMove = MoveComp.MakeFrameMovement(n"CastleEnemyChargerTrapped");
		CalculateFrameMove(FrameMove, DeltaTime);
		MoveCharacter(FrameMove, n"CastleEnemyChargerTrapped");
		
		CrumbComp.LeaveMovementCrumb();
	}	

	void CalculateFrameMove(FHazeFrameMovement& FrameMove, float DeltaTime)
	{	
		if (HasControl())
		{		
			FVector ToTrap = ChargerComp.Trap.ActorLocation - Charger.ActorLocation;

			FVector Velocity = ToTrap.GetSafeNormal() * SpeedToTrap;
			FVector DeltaMove = Velocity * DeltaTime;

			if (ToTrap.Size() < DeltaMove.Size())
				DeltaMove = ToTrap;

			FrameMove.ApplyDelta(DeltaMove);
		}
		else
		{
			FHazeActorReplicationFinalized ConsumedParams;
			CrumbComp.ConsumeCrumbTrailMovement(DeltaTime, ConsumedParams);
			FrameMove.ApplyConsumedCrumbData(ConsumedParams);
		}

		FrameMove.ApplyTargetRotationDelta(); 		
	}

	bool IsTrapSuccessful() const
	{
		FVector ToTrap = ChargerComp.Trap.ActorLocation - Charger.ActorLocation;
		ToTrap.Z = 0.f;
		
		FVector HorizontalToTrap = ToTrap.ConstrainToPlane(Owner.ActorForwardVector);
		if (HorizontalToTrap.Size() > ChargerComp.Trap.HorizontalAcceptanceDistance)
			return false;

		FVector ForwardToTrap = ToTrap.ConstrainToPlane(Owner.ActorRightVector);
		if (ForwardToTrap.Size() > ChargerComp.Trap.ForwardAcceptanceDistance)
			return false;

		return true;
	}
}
