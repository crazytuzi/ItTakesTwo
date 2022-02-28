
import Vino.Movement.Components.MovementComponent;
import Cake.LevelSpecific.Garden.Sickle.Enemy.SickleCuttableComponent;
import Vino.Movement.MovementSystemTags;
import Cake.LevelSpecific.Garden.Vine.VineImpactComponent;
import Cake.LevelSpecific.Garden.Sickle.Enemy.EnemyAir.SickleEnemyAirComponent;
import Cake.LevelSpecific.Garden.Sickle.Enemy.SickleEnemySpawnManagerComponent;


class USickleEnemyAirLockedByVineCapability : UHazeCapability
{
	default CapabilityTags.Add(n"SickleEnemyAlive");
	default CapabilityTags.Add(CapabilityTags::Movement);

	default TickGroup = ECapabilityTickGroups::BeforeMovement;

	const float StartFlyDelay = 0.5f;
	const float InvulerableToNewImpact = 4.f;

  	ASickleEnemy AiOwner;
	USickleEnemyAirComponent AiComponent;
	UVineImpactComponent VineImpactComponent;
	USickleEnemySpawnManagerComponent SpawnEnemyComp;
	bool bHasForcedVineRelease = false;
	bool bBecameGrounded = false;
	float TargetRadialProgress = 0;
	float TimeToActivateVineImpact = 0.f;
	float TimeLeftToStartFlying = 0;
	bool bWineHasReleased = false;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		AiOwner = Cast<ASickleEnemy>(Owner);
		AiComponent = USickleEnemyAirComponent::Get(AiOwner);
		VineImpactComponent = UVineImpactComponent::Get(AiOwner);
		SpawnEnemyComp = USickleEnemySpawnManagerComponent::Get(AiOwner);
		AiOwner.SickleCuttableComp.bInvulnerable = true;
		AiOwner.SickleCuttableComp.ChangeValidActivator(EHazeActivationPointActivatorType::None);
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		if(VineImpactComponent.CurrentWidgetRadialProgress != TargetRadialProgress)
		{
			const float Multiplier = TargetRadialProgress > 0 ? 3.f : 1.f;
			VineImpactComponent.CurrentWidgetRadialProgress = FMath::FInterpConstantTo(VineImpactComponent.CurrentWidgetRadialProgress, TargetRadialProgress, DeltaTime, Multiplier);
			if(VineImpactComponent.CurrentWidgetRadialProgress > 0.99f)
				VineImpactComponent.CurrentWidgetRadialProgress = 1.f;
		}

		if(TimeToActivateVineImpact > 0.f && !IsActive())
		{
			TimeToActivateVineImpact -= DeltaTime;
			if(TimeToActivateVineImpact <= 0)
			{
				VineImpactComponent.SetCanActivate(true, this);
				TimeToActivateVineImpact = 0;
			}
		}

		TargetRadialProgress = 0;
	}

    UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(!AiComponent.CanCalculateMovement())
			return EHazeNetworkActivation::DontActivate;

		if(!AiOwner.bIsBeeingHitByVine)
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(!AiComponent.CanCalculateMovement())
			return EHazeNetworkDeactivation::DeactivateLocal;

		if(TimeLeftToStartFlying <= 0)
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	bool RemoteAllowShouldActivate(FCapabilityRemoteValidationParams ActivationParams) const
	{
		return AiComponent.CanCalculateMovement();
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
    {	
		AiOwner.CleanupCurrentMovementTrail();
		AiComponent.CurrentFlyHeight = 0;		
		AiOwner.SickleCuttableComp.bInvulnerable = false;
		AiOwner.SickleCuttableComp.ChangeValidActivator(EHazeActivationPointActivatorType::May);
		SpawnEnemyComp.DisableSpawning(this);
		TimeLeftToStartFlying = StartFlyDelay;
		bWineHasReleased = false;
		bBecameGrounded = false;

		
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		AiOwner.SickleCuttableComp.bInvulnerable = true;
		AiOwner.SickleCuttableComp.ChangeValidActivator(EHazeActivationPointActivatorType::None);
	
		bHasForcedVineRelease = false;
		SpawnEnemyComp.EnableSpawning(this);
		SpawnEnemyComp.ResetSpawnCount();

		if(bBecameGrounded && DeactivationParams.DeactivationReason == ECapabilityStatusChangeReason::Natural)
		{	
			if(AiComponent.MoveAwayFromGroundEffect != nullptr)
			{
				Niagara::SpawnSystemAtLocation(AiComponent.MoveAwayFromGroundEffect, AiOwner.GetActorLocation(), AiOwner.GetActorRotation());
			}
		}

		if(TimeToActivateVineImpact > 0)
		{
			AiOwner.Mesh.SetAnimFloatParam(n"InvulnerableMovement", TimeToActivateVineImpact);
		}
	}  

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{		
		FHazeFrameMovement FinalMovement = AiComponent.MakeFrameMovement(n"SickleEnemyAirVineLock");
		
		auto Cody = Game::GetCody();
		FVector DirToCody = Cody.GetActorLocation() - AiOwner.GetActorLocation();
		DirToCody = DirToCody.ConstrainToPlane(FVector::UpVector).GetSafeNormal();
		if(DirToCody.IsNearlyZero())
			DirToCody = Cody.GetActorForwardVector();

		
		if(HasControl())
		{
			const float ActiveTime = ActiveDuration;
			if(!AiComponent.IsGrounded() || ActiveDuration < 0.5f)
			{
				FinalMovement.OverrideStepDownHeight(1.f);
 				FinalMovement.ApplyVelocity(-FVector::UpVector * 3000.f);
				AiComponent.SetTargetFacingDirection(DirToCody, 10.f);	
			}
			else
			{
				FinalMovement.OverrideStepDownHeight(20.f);
				AiComponent.SetTargetFacingDirection(DirToCody);
			}
			FinalMovement.ApplyTargetRotationDelta();
		}
		else
		{
			FHazeActorReplicationFinalized ReplicationData;
			AiOwner.CrumbComponent.ConsumeCrumbTrailMovement(DeltaTime, ReplicationData);
			FinalMovement.ApplyConsumedCrumbData(ReplicationData);	
		}
		
		AiComponent.Move(FinalMovement);
		AiOwner.CrumbComponent.LeaveMovementCrumb();

		TargetRadialProgress = FMath::Lerp(1.f, 0.f, FMath::Min(ActiveDuration / AiComponent.MaxLockedByVineTime, 1.f));
		VineImpactComponent.CurrentWidgetRadialProgress = TargetRadialProgress;

		if(ActiveDuration > AiComponent.MaxLockedByVineTime && !bHasForcedVineRelease)
		{
			bHasForcedVineRelease = true;
			UHazeCrumbComponent::Get(Game::GetCody()).LeaveAndTriggerDelegateCrumb(FHazeCrumbDelegate(this, n"Crumb_LoseVineHit"), FHazeDelegateCrumbParams());
		}

		if(!bBecameGrounded)
		{
			auto Players = Game::GetPlayers();
			for(auto Player : Players)
			{
				if(Trace::ComponentOverlapComponent(
					Player.CapsuleComponent,
					AiOwner.CapsuleComponent,
					AiOwner.CapsuleComponent.WorldLocation,
					AiOwner.CapsuleComponent.ComponentQuat,
					bTraceComplex = false))
				{
					Player.KillPlayer(AiComponent.DeathEffect);
				}
			}

			bBecameGrounded = AiComponent.IsGrounded();
			if(bBecameGrounded)
			{
				AiOwner.Mesh.SetAnimBoolParam(n"Landed", true);
				AiOwner.SetCapabilityActionState(n"GardenFlyerGrounded", EHazeActionState::ActiveForOneFrame);
				AiOwner.HazeAkComp.SetRTPCValue("Rtpc_Characters_Enemies_GardenFlyer_IsLockedByVine", 1.f);

				if(AiComponent.GroundedEffect != nullptr)
					Niagara::SpawnSystemAtLocation(AiComponent.GroundedEffect, AiOwner.GetActorLocation(), AiOwner.GetActorRotation());
			}
		}

		if(!AiOwner.bIsBeeingHitByVine)
		{
			if(!bWineHasReleased)
			{
				if(bBecameGrounded)
				{
					bWineHasReleased = true;
					TimeToActivateVineImpact = InvulerableToNewImpact;
					VineImpactComponent.SetCanActivate(false, this);
					AiOwner.Mesh.SetAnimFloatParam(n"VineHoldReleased", TimeLeftToStartFlying);
					AiOwner.HazeAkComp.SetRTPCValue("Rtpc_Characters_Enemies_GardenFlyer_IsLockedByVine", 0.f);
				}
				else
				{
					TimeLeftToStartFlying = 0;
				}
			}
			else
			{
				TimeLeftToStartFlying -= DeltaTime;
			}
		}
	}

	UFUNCTION(NotBlueprintCallable)
	void Crumb_LoseVineHit(FHazeDelegateCrumbData CrumbData)
	{
		auto Cody = Game::GetCody();
		Cody.SetCapabilityActionState(n"ForceVineRelease", EHazeActionState::ActiveForOneFrame);
		AiOwner.SetAnimBoolParam(n"ForceVineRelease", true);
	}
}
