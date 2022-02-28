import Cake.LevelSpecific.Garden.Sickle.Enemy.SickleEnemy;
import Cake.LevelSpecific.Garden.Vine.VineImpactComponent;
import Cake.LevelSpecific.Garden.Sickle.Enemy.SickleEnemyComponent;
import Cake.LevelSpecific.Garden.Sickle.Enemy.EnemyUnderGround.SickleEnemyUnderGroundComponent;


class USickleEnemyUnderGroundUprootedCapability : UHazeCapability
{
	default CapabilityTags.Add(n"SickleEnemyAlive");
	default CapabilityTags.Add(n"SickleEnemyUnderGround");

	default TickGroup = ECapabilityTickGroups::BeforeMovement;

	const float TimeUntilBurrowAgain = 0.6f;
	const float MaxHoldTime = 5.5f;
	
	ASickleEnemy AiOwner;
	USickleEnemyUnderGroundComponent AiComponent; 
	USickleCuttableHealthComponent HealthComp;
	UVineImpactComponent VineComp;
	FVector ExposedAtLocation;
	bool bHasExposedLocation = false;
	float ForceReleaseVineHoldTimeLeft = 0;
	float DeactivationTimer = 0;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		AiOwner = Cast<ASickleEnemy>(Owner);
		AiComponent = USickleEnemyUnderGroundComponent::Get(Owner);
		HealthComp = AiOwner.SickleCuttableComp;
		HealthComp.ChangeValidActivator(EHazeActivationPointActivatorType::None);

		VineComp = UVineImpactComponent::Get(AiOwner);
		VineComp.AttachmentMode = EVineAttachmentType::Component;
		VineComp.CurrentWidgetRadialProgress = 0;
	}

	UFUNCTION(BlueprintOverride)
	void OnBlockTagAdded(FName Tag)
	{
		// This will force the enemy to stay up when dead
		if(Tag == n"SickleEnemyAlive")
		{
			AiComponent.ShowBody(AiOwner);
		}
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(!AiOwner.bIsBeeingHitByVine)
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(!AiOwner.bIsBeeingHitByVine && DeactivationTimer <= 0)
				return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		AiComponent.ShowBody(this);
		SetMutuallyExclusive(n"SickleEnemyUnderGround", true);

		AiOwner.BlockMovementSyncronization(this);
		AiOwner.BlockTargetPicking();
		AiOwner.CapsuleComponent.SetCollisionProfileName(AiComponent.OriginalCollisionProfile);
		HealthComp.ChangeValidActivator(EHazeActivationPointActivatorType::May);

		if(Game::GetCody().HasControl())
		{
			NetSetExposedLocation(AiOwner.GetActorLocation());
		}
		else if(!bHasExposedLocation)
		{
			ExposedAtLocation = AiOwner.GetActorLocation();
		}
		
		ForceReleaseVineHoldTimeLeft = MaxHoldTime;
		VineComp.CurrentWidgetRadialProgress = 1.f;
		DeactivationTimer = TimeUntilBurrowAgain;

		AiOwner.BlockAttackWithInstigator(this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		AiComponent.RemoveMeshOffsetInstigator(this);
		SetMutuallyExclusive(n"SickleEnemyUnderGround", false);
		
		AiOwner.UnblockMovementSyncronization(this);
		AiOwner.UnblockTargetPicking();
		HealthComp.ChangeValidActivator(EHazeActivationPointActivatorType::None);
		ForceReleaseVineHoldTimeLeft = 0.f;
		bHasExposedLocation = false;

		AiOwner.UnblockAttackWithInstigator(this, 3.f);
		if(ActiveDuration > 0.5f && AiOwner.IsAlive())
			AiComponent.EnableSpawning();		
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		if(!AiOwner.bIsBeeingHitByVine)
		{
			DeactivationTimer -= DeltaTime;
		}	
		else
		{
			DeactivationTimer = TimeUntilBurrowAgain;
		}
			
		ForceReleaseVineHoldTimeLeft -= DeltaTime;
		if(ForceReleaseVineHoldTimeLeft <= 0)
		{
			VineComp.CurrentWidgetRadialProgress = 0;
			Game::GetCody().SetCapabilityActionState(n"ForceVineRelease", EHazeActionState::ActiveForOneFrame);
		}
		else
		{
			VineComp.CurrentWidgetRadialProgress = ForceReleaseVineHoldTimeLeft / MaxHoldTime;
		}
			
		FHazeFrameMovement FinalMovement = AiComponent.MakeFrameMovement(n"SickleEnemyUprootMovement");
		FinalMovement.OverrideStepDownHeight(1.f);
		
		// We fix up the location so we are at the same place on remote and control
		const float MovementSpeed = AiComponent.MovementSpeed * 3.f;
		const FVector DiffToTarget = (ExposedAtLocation - AiOwner.GetActorLocation());
		const float DistanceToTarget = DiffToTarget.Size();
		const float MoveAmount = FMath::Min(DistanceToTarget, MovementSpeed * DeltaTime);
		FinalMovement.ApplyDeltaWithCustomVelocity(DiffToTarget.GetSafeNormal() * MoveAmount, FVector::ZeroVector);
		FinalMovement.ApplyTargetRotationDelta();
		AiComponent.Move(FinalMovement);
	}

	UFUNCTION(NetFunction)
	void NetSetExposedLocation(FVector Loc)
	{
		ExposedAtLocation = Loc;
		bHasExposedLocation = true;
	}
}