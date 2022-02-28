import Vino.ActivationPoint.ActivationPointStatics;
import Peanuts.DamageFlash.DamageFlashStatics;

event void FOnCutWithSickle(int DamageAmount);
event void FOnSickleAttackerActivationStatus(bool bStatus);

enum ESickleAttackMovementType
{
	// Will translate to the attack distance
	TranslateToAttackDistance,

	// Will translate to the attack distance and apply gravity after
	TranslateToAttackDistanceAndApplyGravity,
};

enum ESickleTargetGroundedType
{
	Default,
	Grounded,
	InAir
};

// Default Class for cutable component
class USickleCuttableComponent : UHazeActivationPoint
{
	default EvaluationInterval = EHazeActivationPointTickIntervalType::EveryForthFrame;
	default ValidationIdentifier = EHazeActivationPointIdentifierType::Combat;
	default ValidationType = EHazeActivationPointActivatorType::May;
	default BiggestDistanceType = EHazeActivationPointDistanceType::Targetable;
	default InitializeDistance(EHazeActivationPointDistanceType::Targetable, 3000.f);
	default InitializeDistance(EHazeActivationPointDistanceType::Selectable, 1500.f);

	/* How far away from the point will the player lerp to
	 * If Min value is > 0; the player will lerp backwards if standing to close
	*/
	UPROPERTY(Category = "Attribute")
	FHazeMinMax PlayerAttackDistance = FHazeMinMax(0.f, 250.f);

	// If true, the collision radius of both actors will be included in the distance
	UPROPERTY(Category = "Attribute")
	bool bPlayerAttackDistanceIncludeCollisonRadiuses = false;

	// This name is included in the attack animation request
	UPROPERTY(Category = "Attribute")
	FName AttackTypeName = NAME_None;

	// Changes how the actor will relate to this point when attacking
	UPROPERTY(Category = "Attribute")
	ESickleAttackMovementType AttackMovementType = ESickleAttackMovementType::TranslateToAttackDistance;

	UPROPERTY(Category = "Attribute")
	bool bUseOwnerInsteadOfComponentAsTarget = false;

	// If you want the target to count as a grounded type always
	UPROPERTY(Category = "Attribute")
	ESickleTargetGroundedType GroundedType = ESickleTargetGroundedType::Default;

	/* If the attachtype is AttachRelativeToTarget
	 * the player will attach to the specified mesh socket
	*/
	UPROPERTY(Category = "Attribute")
	FName AttackAttachmentSocket = NAME_None;

	// We start at half so we can bring it up or down
	UPROPERTY(EditDefaultsOnly, Category = "Attribute")
	float BonusScoreMultiplier = 0.5f;

	bool bOwnerIsDead = false;
	bool bOwnerForcesDeactivation = false;

	UPROPERTY()
	FOnCutWithSickle OnCutWithSickle;

	UPROPERTY(Category = "Attribute")
	TArray<AActor> ActorsToIgnoreInFreeSightCheck;

	// If the player overlaps this actor, we cant activate this point
	UPROPERTY(Category = "Attribute")
	bool bPlayerOverlappingActorInvalidates = true;

	// Perform a trace to validate if this is can be activated
	UPROPERTY(Category = "Attribute")
	bool bInvalidateIfObstructed = true;

	// Perform a trace and the found component needs to be the parent component of the activationpoint
	UPROPERTY(Category = "Attribute", meta = (EditCondition = "bInvalidateIfObstructed"))
	bool bInvalidateIfParentComponentIsUnreachable = false;

	// If true, the player needs to become grounded before attacking the next target
	UPROPERTY(Category = "Attribute")
	bool bBlockAttackerUntilGroundedOnDeath = false;

	UPROPERTY()
	FOnSickleAttackerActivationStatus OnActivationStatusChanged;

	FGetInvulnerabilityForPlayer GetCustomInvulnerabilityForPlayer;

	bool GetInvulnerableStatus(AHazePlayerCharacter ForPlayer) const
	{
		if(GetCustomInvulnerabilityForPlayer.IsBound())
			return GetCustomInvulnerabilityForPlayer.Execute(ForPlayer);
		else
			return false;
	}

	bool ApplyDamage(int DamageAmount, AHazePlayerCharacter DamageInstigator, bool _bInvulnerable)
	{
		if(DamageInstigator != nullptr)
		{
			DamageInstigator.SetCapabilityAttributeValue(n"AudioSickleDamageAmount", DamageAmount);
			
			if(DamageInstigator.IsMay())
			{
				OnCutWithSickle.Broadcast(DamageAmount);
				DamageInstigator.SetCapabilityActionState(n"AudioSickleImpact", EHazeActionState::ActiveForOneFrame);
			}
		}
		else
		{
			OnCutWithSickle.Broadcast(DamageAmount);
		}

		return true;
	}

	UFUNCTION(BlueprintOverride)
	EHazeActivationPointStatusType SetupActivationStatus(AHazePlayerCharacter Player, FHazeQueriedActivationPoint& Query)const
	{	
		if(bOwnerIsDead)
			return EHazeActivationPointStatusType::InvalidAndHidden;

		if(bOwnerForcesDeactivation)
			return EHazeActivationPointStatusType::InvalidAndHidden;

		const FVector TargetPosition = GetPlayerAttackPosition(Player);
		auto PlayerMovementComp = UHazeMovementComponent::Get(Player);
		const float HorizontalDistance = TargetPosition.Dist2D(Player.GetActorLocation(), PlayerMovementComp.WorldUp);
		if(bPlayerOverlappingActorInvalidates)
		{
			if(Query.DistanceType == EHazeActivationPointDistanceType::Selectable)
			{
				TArray<FOverlapResult> Overlaps;
				if(PlayerMovementComp.OverlapTrace(TargetPosition, Overlaps))
				{
					for(const FOverlapResult& Overlap : Overlaps)
					{
						if(Overlap.Actor == Owner)
							return EHazeActivationPointStatusType::InvalidAndHidden;
					}		
				}
			}
		}

		if(bInvalidateIfObstructed)
		{
			FFreeSightToActivationPointParams ExtraStuff;
			ExtraStuff.TrazeFromZOffset = 0.f;
			ExtraStuff.IgnoredActors = ActorsToIgnoreInFreeSightCheck;
			ExtraStuff.bOnlyValidIfParentComponentIsHit = bInvalidateIfParentComponentIsUnreachable;

			if(HorizontalDistance > Player.GetCollisionSize().X * 4.f)
			{
				// when far away we only do a linetrace
				if(!ActivationPointsStatics::CanPlayerReachActivationPoint(Player, Query, ExtraStuff))
					return EHazeActivationPointStatusType::InvalidAndHidden;
			}
			else
			{
				// When close, we do a capsule trace to make sure we dont hit edges
				if(!ActivationPointsStatics::CanPlayerReachActivationPoint_Expensive(Player, Query, ExtraStuff))
					return EHazeActivationPointStatusType::InvalidAndHidden;
			}
		}

		return EHazeActivationPointStatusType::Valid;
	}

	UFUNCTION(BlueprintOverride)
	EHazeActivationPointStatusType SetupWidgetVisibility(AHazePlayerCharacter Player, FHazeQueriedActivationPointWithWidgetInformation Query) const
	{	
		if(!Query.IsValid())
			return EHazeActivationPointStatusType::InvalidAndHidden;

		if(Query.IsActive())
			return EHazeActivationPointStatusType::Valid;

		if(Query.WasRecentlyActivatedBy(Player))
			return EHazeActivationPointStatusType::Valid;

		if(!Query.IsTargetedBy(Player))
			return EHazeActivationPointStatusType::InvalidAndHidden;

		if(Query.DistanceType != EHazeActivationPointDistanceType::Selectable)
			return EHazeActivationPointStatusType::InvalidAndHidden;
		
		return EHazeActivationPointStatusType::Valid;
	}

	UFUNCTION(BlueprintOverride)
	float SetupValidationScoreAlpha(AHazePlayerCharacter Player, FHazeQueriedActivationPoint Query, float CompareDistanceAlpha) const
	{	
		const float DistanceMaxScore = GetDistanceScore();
		const float CameraMaxScore = GetCameraScore();
		const float FinalBonusScore = Query.WasRecentlyActivatedBy(Player) ? 100 : 0;
		const float MaxScore = DistanceMaxScore + CameraMaxScore + FinalBonusScore;
	
		float FinalDistanceScore = 0;
		float FinalCameraScore = 0;

		const FVector WorldUp = Player.GetMovementWorldUp();

		// Add distance score
		const float DistanceAlpha = (CompareDistanceAlpha + Query.DistanceAlpha) * 0.5f;
		const float DistanceAlphaConverted = 1.f - DistanceAlpha;
		FinalDistanceScore = DistanceAlphaConverted * DistanceMaxScore;

		// Get camera score
		const FVector SearchDirection = Player.ViewRotation.ForwardVector.ConstrainToPlane(WorldUp).GetSafeNormal();
		const FVector PointOrigin = Query.Transform.GetLocation();
		const FVector PlayerOrigin = Player.GetActorCenterLocation();

		const FVector DirToPoint = (PointOrigin - PlayerOrigin).GetSafeNormal();
		const float DotValue = (DirToPoint.DotProduct(SearchDirection) + 1) * 0.5f;
		FinalCameraScore += DotValue * CameraMaxScore;

		// Calculate the alpha
		const float BonusMaxScore = 100 * BonusScoreMultiplier;
		const float TotalScore = FinalDistanceScore + FinalCameraScore + FinalBonusScore + BonusMaxScore;
		return TotalScore / MaxScore;
	}

	protected float GetDistanceScore() const
	{
		return 100;
	}

	protected float GetCameraScore() const
	{
		return 100;
	}

	UFUNCTION(BlueprintOverride)
	FTransform GetTransformFor(AHazePlayerCharacter Player) const
	{	
		if(bUseOwnerInsteadOfComponentAsTarget)
		{
			FTransform ActorTransform = Owner.GetActorTransform();
			
			auto HazeOwner = Cast<AHazeActor>(Owner);	
			if(HazeOwner != nullptr)
				ActorTransform.SetLocation(HazeOwner.GetActorCenterLocation());
				
			ActorTransform.SetScale3D(FVector(1.f));
			return ActorTransform;
		}
		else
		{
			FTransform ComponentTransform = GetWorldTransform();
			ComponentTransform.SetScale3D(FVector(1.f));
			return ComponentTransform;
		}
	}

	FVector GetAttackPositionFor(AHazePlayerCharacter Player) const
	{
		if(bUseOwnerInsteadOfComponentAsTarget)
		{		
			return Owner.GetActorLocation();
		}
		else
		{
			return GetWorldLocation();
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnPointActivatedBy(AHazePlayerCharacter Player)
	{
		OnActivationStatusChanged.Broadcast(true);
	}

	UFUNCTION(BlueprintOverride)
	void OnPointDeactivatedBy(AHazePlayerCharacter Player)
	{
		OnActivationStatusChanged.Broadcast(false);
	}

	FVector GetPlayerAttackPosition(AHazePlayerCharacter Player) const
	{
		AHazeActor HazeOwner = Cast<AHazeActor>(Owner);

		// Handle the movepoints attachment setup
		FVector TargetLocation = GetAttackPositionFor(Player);
		const FVector TargetWorldUp = HazeOwner.GetMovementWorldUp();

		// Modify the position to be at the feet of the actors location
		FVector PlayerLocation = Player.GetActorLocation();
		PlayerLocation = PlayerLocation.ConstrainToPlane(TargetWorldUp);
		PlayerLocation += TargetLocation.ConstrainToDirection(TargetWorldUp);

		float DistanceToTargetLocation = Player.GetHorizontalDistanceTo(HazeOwner);
		DistanceToTargetLocation += Player.GetCollisionSize().X;

		float TargetCollisionSize = 0;
		auto TargetCollision = UShapeComponent::Get(HazeOwner);
		if(TargetCollision != nullptr)
		{
			TargetCollisionSize = TargetCollision.GetCollisionShape().GetSphereRadius();
		}
		DistanceToTargetLocation += TargetCollisionSize;
		
		if(bPlayerAttackDistanceIncludeCollisonRadiuses)
		{
			const float IncludeRadius = TargetCollisionSize + Player.GetCollisionSize().X;
			if(DistanceToTargetLocation > PlayerAttackDistance.Max + IncludeRadius)
			{
				DistanceToTargetLocation = PlayerAttackDistance.Max + IncludeRadius;
			}
			else if(DistanceToTargetLocation <= PlayerAttackDistance.Min + IncludeRadius)
			{
				DistanceToTargetLocation = PlayerAttackDistance.Min + IncludeRadius;
			}
		}
		else
		{
			if(DistanceToTargetLocation > PlayerAttackDistance.Max)
			{
				DistanceToTargetLocation = PlayerAttackDistance.Max;
			}
			else if(DistanceToTargetLocation <= PlayerAttackDistance.Min)
			{
				DistanceToTargetLocation = PlayerAttackDistance.Min;
			}
		}

	
		// Get the direction to the player
		FVector DirToPlayerFromTarget = (PlayerLocation - TargetLocation);
		if(DirToPlayerFromTarget.SizeSquared() > 1)
		{
			DirToPlayerFromTarget = DirToPlayerFromTarget.GetSafeNormal();
		}
		else
		{
			DirToPlayerFromTarget = Player.GetActorVelocity();
			DirToPlayerFromTarget += (-HazeOwner.GetActorForwardVector()) * 200.f;
			DirToPlayerFromTarget.Normalize();
		}

		// Modify the location if we are to far away, or to close, else, just face the target
		TargetLocation += DirToPlayerFromTarget * DistanceToTargetLocation;

		//System::DrawDebugLine(TargetLocation + (FVector::UpVector * 500), TargetLocation - (FVector::UpVector * 500), Thickness = 10.f);
		return TargetLocation;
	}
}

delegate bool FGetInvulnerabilityForPlayer(AHazePlayerCharacter Player) const;

// A Cutable Component with Health
class USickleCuttableHealthComponent : USickleCuttableComponent
{
	default BiggestDistanceType = EHazeActivationPointDistanceType::Selectable;

	UPROPERTY(Category = "Attribute")
	int MaxHealth = 100;

	UPROPERTY(BlueprintReadOnly, NotEditable, Category = "Attribute")
    int Health = 0;

	UPROPERTY(Category = "Attribute")
	bool bInvulnerable = false;

	// The max amount that can diff between the attack and the owner to be valid.
	UPROPERTY(Category = "Attribute")
	float MaxVerticalDistance = -1;

	UPROPERTY(EditDefaultsOnly, Category = "Attribute|Effects")
	float ImpactFlashTime = 0.2f;

	UPROPERTY(EditDefaultsOnly, Category = "Attribute|Effects")
	TSubclassOf<UCameraShakeBase> ImpactCameraShake;

	UPROPERTY(EditDefaultsOnly, Category = "Attribute|Effects")
	UNiagaraSystem ImpactEffect;

	UPROPERTY(EditDefaultsOnly, Category = "Attribute|Effects")
	UForceFeedbackEffect ImpactRumble;
	
	UPROPERTY(EditDefaultsOnly, Category = "Attribute|InvulnerableEffects")
	TSubclassOf<UCameraShakeBase> InvulnerableImpactCameraShake;

	UPROPERTY(EditDefaultsOnly, Category = "Attribute|InvulnerableEffects")
	UNiagaraSystem InvulnerableImpactEffect;

	UPROPERTY(EditDefaultsOnly, Category = "Attribute|InvulnerableEffects")
	UForceFeedbackEffect InvulnerableImpactRumble;

	TArray<UObject> CustomBlockers;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Health = MaxHealth;
	}

	bool GetInvulnerableStatus(AHazePlayerCharacter ForPlayer) const override
	{
		if(GetCustomInvulnerabilityForPlayer.IsBound())
			return GetCustomInvulnerabilityForPlayer.Execute(ForPlayer);
		else
			return bInvulnerable;
	}

	UFUNCTION(BlueprintOverride)
	EHazeActivationPointStatusType SetupActivationStatus(AHazePlayerCharacter Player, FHazeQueriedActivationPoint& Query)const override
	{
		if(CustomBlockers.Num() > 0)
			return EHazeActivationPointStatusType::InvalidAndHidden;

		const EHazeActivationPointStatusType WantedStatus = Super::SetupActivationStatus(Player, Query);
		if(WantedStatus != EHazeActivationPointStatusType::Valid)
			return WantedStatus;

		if(MaxVerticalDistance < 0)
			return WantedStatus;

		const float VerticalDistance = Query.Transform.Location.Z - Player.ActorLocation.Z;
		const float VerticalAbsDistance = FMath::Abs(VerticalDistance);

		if(VerticalDistance <= 0)
			return EHazeActivationPointStatusType::Valid;

		if(VerticalAbsDistance <= MaxVerticalDistance)
			return EHazeActivationPointStatusType::Valid;

		return EHazeActivationPointStatusType::Invalid;
	}

	bool ApplyDamage(int DamageAmount, AHazePlayerCharacter DamageInstigator, bool _bInvulnerable) override
	{
		if(_bInvulnerable)
		{
			Super::ApplyDamage(0, DamageInstigator, _bInvulnerable);
			
			if(InvulnerableImpactEffect != nullptr)
			{
				// Niagara::SpawnSystemAttached(InvulnerableImpactEffect, 
				// 	Owner.RootComponent, 
				// 	NAME_None, 
				// 	GetTransformFor(DamageInstigator).GetLocation(), 
				// 	Owner.GetActorRotation(),
				// 	EAttachLocation::KeepWorldPosition,
				// 	true);
					
				Niagara::SpawnSystemAtLocation(InvulnerableImpactEffect, GetTransformFor(DamageInstigator).GetLocation());

			}

			// OW: We didnt want this, right?
			//if(InvulnerableImpactCameraShake.IsValid())
			//	DamageInstigator.PlayCameraShake(InvulnerableImpactCameraShake);

			if(InvulnerableImpactRumble != nullptr)
				DamageInstigator.PlayForceFeedback(InvulnerableImpactRumble, false, true, n"ApplyDamage");

			return false;
		}
		else if(DamageInstigator != nullptr)
		{
			Health = FMath::Max(Health - DamageAmount, 0);

			// May specific
			if(DamageInstigator.IsMay())
			{
				if(Health <= 0 && bBlockAttackerUntilGroundedOnDeath)
					DamageInstigator.SetCapabilityActionState(n"SickleAttackBlockedUntilGrounded", EHazeActionState::ActiveForOneFrame);
			}

			if(ImpactEffect != nullptr)
			{
				// Niagara::SpawnSystemAttached(ImpactEffect, 
				// 	Owner.RootComponent, 
				// 	NAME_None, 
				// 	GetTransformFor(DamageInstigator).GetLocation(), 
				// 	Owner.GetActorRotation(),
				// 	EAttachLocation::KeepWorldPosition,
				// 	true);

				Niagara::SpawnSystemAtLocation(ImpactEffect, GetTransformFor(DamageInstigator).GetLocation());
			}

			//if(ImpactCameraShake.IsValid())
			//	DamageInstigator.PlayCameraShake(ImpactCameraShake);

			if(ImpactRumble != nullptr)
				DamageInstigator.PlayForceFeedback(ImpactRumble, false, true, n"ApplyDamage");

			if(ImpactFlashTime > 0)
				FlashActor(Cast<AHazeActor>(Owner), ImpactFlashTime);

			Super::ApplyDamage(DamageAmount, DamageInstigator, _bInvulnerable);
			return true;
		}
		else
		{
			Health = FMath::Max(Health - DamageAmount, 0);
			if(ImpactEffect != nullptr)
			{
				Niagara::SpawnSystemAtLocation(ImpactEffect, GetWorldLocation());
			}

			Super::ApplyDamage(DamageAmount, DamageInstigator, _bInvulnerable);
			return true;
		}
	}

	protected float GetDistanceScore() const
	{
		if(bInvulnerable)
			return Super::GetDistanceScore() * 1.5f;
		else
			return Super::GetDistanceScore() * 2.0f;
	}

	protected float GetCameraScore() const
	{
		return Super::GetCameraScore() * 2.0f;		
	}
}
