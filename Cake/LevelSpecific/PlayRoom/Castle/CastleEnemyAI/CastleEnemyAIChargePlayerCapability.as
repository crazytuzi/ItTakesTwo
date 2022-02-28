import Cake.LevelSpecific.PlayRoom.Castle.CastleEnemy.CastleEnemy;
import Cake.LevelSpecific.PlayRoom.Castle.CastleStatics;
import Vino.Movement.Capabilities.Standard.CharacterMovementCapability;

class UCastleEnemyAIChargePlayerCapability : UCharacterMovementCapability
{
    default TickGroupOrder = 99;
    default TickGroup = ECapabilityTickGroups::BeforeMovement;
    default CapabilityTags.Add(n"CastleEnemyAI");
    default CapabilityTags.Add(n"CastleEnemyCharge");

    default CapabilityDebugCategory = n"Castle";

    UPROPERTY()
    float ChargeRange = 1200.f;
    UPROPERTY()
    float ChargeSpeed = 2200.f;    
    UPROPERTY()
    FVector ChargeLocation;

    UPROPERTY()
    float ChargeRampUpTime = 1.2f;    
    UPROPERTY()
    float ChargeRampUpCurrent;

    UPROPERTY()
    float ChargeStunTime = 3.f;
    UPROPERTY()
    float ChargeStunCurrent;
    UPROPERTY()
    bool ChargeComplete = false;

    UPROPERTY()
    AHazePlayerCharacter ChargeTarget;

    FVector ToChargeTarget;

    ACastleEnemy Enemy;

	bool bFinishedOnRemote = true;

    UFUNCTION(BlueprintOverride)
    void Setup(FCapabilitySetupParams Params)
    {
        Enemy = Cast<ACastleEnemy>(Owner);
		Super::Setup(Params);
    }
        
    UFUNCTION(BlueprintOverride)
    void PreTick(float DeltaTime)
    {
        if (!IsActive() && HasControl())
        {
            ChargeTarget = GetValidChargeTarget();
        }
    }   

    AHazePlayerCharacter GetValidChargeTarget()
    {
        if (Enemy.AggroedPlayer != nullptr)
        {
            float Distance = (Owner.ActorLocation - Enemy.AggroedPlayer.ActorLocation).Size();

            if (Distance <= ChargeRange)
                return Enemy.AggroedPlayer;
        }
        return nullptr;
    }

    UFUNCTION(BlueprintOverride)
    EHazeNetworkActivation ShouldActivate() const
    {
		if (!bFinishedOnRemote)
			return EHazeNetworkActivation::DontActivate; 
        if (ChargeTarget != nullptr)
            return EHazeNetworkActivation::ActivateUsingCrumb; 
        return EHazeNetworkActivation::DontActivate; 
    }

    UFUNCTION(BlueprintOverride)
    EHazeNetworkDeactivation ShouldDeactivate() const
    {
        if (ChargeComplete)
            return EHazeNetworkDeactivation::DeactivateLocal; 
        return EHazeNetworkDeactivation::DontDeactivate; 
    }

    UFUNCTION(BlueprintOverride)
	void ControlPreActivation(FCapabilityActivationSyncParams& ActivationParams)
	{
		bFinishedOnRemote = false;

        ToChargeTarget = ChargeTarget.ActorLocation - Enemy.ActorLocation;
		ToChargeTarget.Z = 0.f;
        ToChargeTarget.Normalize();

		ActivationParams.AddVector(n"ToChargeTarget", ToChargeTarget);
		ActivationParams.AddObject(n"ChargeTarget", ChargeTarget);
	}

    UFUNCTION(BlueprintOverride)
    void OnActivated(FCapabilityActivationParams ActivationParams)
    {
		ToChargeTarget = ActivationParams.GetVector(n"ToChargeTarget");
		ChargeTarget = Cast<AHazePlayerCharacter>(ActivationParams.GetObject(n"ChargeTarget"));

        Enemy.BlockCapabilities(CapabilityTags::Movement, this);
        Enemy.BlockCapabilities(n"CastleEnemyAI", this);
        Enemy.BlockCapabilities(n"CastleEnemyMovement", this);

        ChargeRampUpCurrent = 0.f;
        ChargeStunCurrent = 0.f;
        ChargeComplete = false;

        MoveComp.SetTargetFacingRotation(Math::MakeRotFromX(ToChargeTarget), 18.f);

        PlayChargeRampUpAnimation();     
    }

    UFUNCTION(BlueprintEvent)
    void PlayChargeRampUpAnimation()
    {

    }

    UFUNCTION(BlueprintEvent)
    void PlayStunAnimation()
    {

    }

	UFUNCTION(BlueprintEvent)
    void ReleasePinnedPlayer()
    {

    }

	UFUNCTION(NetFunction)
	void NetRemoteSideDone()
	{
		bFinishedOnRemote = true;
	}

	UFUNCTION(NetFunction)
	void NetChargerHit(AActor HitActor)
	{
		CastleChargeActor(HitActor);
		ChargeTarget = nullptr;
	}

    UFUNCTION(BlueprintOverride)
    void TickActive(float DeltaTime)
    {
        FHazeFrameMovement Movement = MoveComp.MakeFrameMovement(n"CastleEnemyCharge");

        // If the owner has hit a wall, will be stunned until time is up
        if (ChargeTarget == nullptr)
        {
            if (ChargeStunCurrent == 0)
                PlayStunAnimation();
            
            if (ChargeStunCurrent < ChargeStunTime)
                ChargeStunCurrent += DeltaTime;   
            else
                ChargeComplete = true;

			Enemy.SendMovementAnimationRequest(Movement, n"CastleEnemyCharge", n"ChargeHit");

			if (!HasControl())
			{
				FHazeActorReplicationFinalized ConsumedParams;
				CrumbComp.ConsumeCrumbTrailMovement(DeltaTime, ConsumedParams);
				Movement.ApplyConsumedCrumbData(ConsumedParams);
			}

			Movement.ApplyTargetRotationDelta();
			Movement.FlagToMoveWithDownImpact();
			MoveComp.Move(Movement);        

			if (HasControl())
				CrumbComp.LeaveMovementCrumb();

			return;
        }

        // If you are 'ramping up' the charge, only rotate
        if (ChargeRampUpCurrent < ChargeRampUpTime)
        {
            ChargeRampUpCurrent += DeltaTime;            
            Movement.ApplyTargetRotationDelta();
            MoveComp.Move(Movement); 

			Enemy.SendMovementAnimationRequest(Movement, n"CastleEnemyCharge", n"ChargeRampUp");
            return;
        }

        FHitResult CollidingHit;
        
        if (HasControl() && MoveComp.IsCollidingWithWall(CollidingHit))
        {
			NetChargerHit(CollidingHit.Actor);
			MoveComp.Move(Movement);
            return;
        }

		if (HasControl())
		{
			FVector Velocity;
			Velocity = ToChargeTarget * ChargeSpeed;

			FVector DeltaMovement;
			DeltaMovement = Velocity * DeltaTime;

			FVector PrevLocation = Enemy.ActorLocation;

			Movement.ApplyVelocity(Velocity);
			Movement.ApplyGravityAcceleration();
			Movement.ApplyActorVerticalVelocity();
		}
		else
		{
			FHazeActorReplicationFinalized ConsumedParams;
			CrumbComp.ConsumeCrumbTrailMovement(DeltaTime, ConsumedParams);
			Movement.ApplyConsumedCrumbData(ConsumedParams);
		}

		Movement.ApplyTargetRotationDelta();
		Movement.FlagToMoveWithDownImpact();
		MoveComp.Move(Movement);        

		Enemy.SendMovementAnimationRequest(Movement, n"CastleEnemyCharge", NAME_None);

		if (HasControl())
			CrumbComp.LeaveMovementCrumb();
    }

    bool CheckForChargeCollision(FVector& DeltaMovement)
    {
		float TraceCapRadius = Enemy.CapsuleComponent.CapsuleRadius;
        float TraceCapHeight = Enemy.CapsuleComponent.CapsuleHalfHeight;

        TArray<EObjectTypeQuery> TraceObjects;
        TraceObjects.Add(EObjectTypeQuery::WorldStatic);
        TArray<AActor> IgnoredActors;   

        FHitResult Hit;

        System::CapsuleTraceSingleForObjects(Enemy.CapsuleComponent.WorldLocation, Enemy.CapsuleComponent.WorldLocation + DeltaMovement, TraceCapRadius, 100, TraceObjects, false, IgnoredActors,  EDrawDebugTrace::Persistent, Hit, true);

        if (Hit.bBlockingHit)           
        {
            FVector DirectionTowardsHit = Hit.Location - Enemy.ActorLocation;
            DirectionTowardsHit *= FVector(1, 1, 0);

            DeltaMovement = DirectionTowardsHit;            
        }

        return Hit.bBlockingHit;
    }

    UFUNCTION(BlueprintOverride)
    void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
    {
        Enemy.UnblockCapabilities(CapabilityTags::Movement, this);
        Enemy.UnblockCapabilities(n"CastleEnemyAI", this);
        Enemy.UnblockCapabilities(n"CastleEnemyMovement", this);
		Enemy.TriggerMovementTransition(this);
		if (!HasControl() || !Network::IsNetworked())
			NetRemoteSideDone();
    }    
}