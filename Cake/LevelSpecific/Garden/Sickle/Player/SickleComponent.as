import Cake.LevelSpecific.Garden.Sickle.Player.Sickle;
import Cake.LevelSpecific.Garden.Sickle.Player.SickleAttackData;
import Peanuts.Outlines.Outlines;
import Cake.LevelSpecific.Garden.Sickle.Enemy.SickleCuttableComponent;
import Cake.LevelSpecific.Garden.Sickle.Animation.LocomotionSickleStateMachineAsset;
import Vino.Movement.Components.MovementComponent;
import Vino.Characters.PlayerCharacter;
import Cake.LevelSpecific.Garden.Sickle.Animation.AnimNotify_SickleAttachment;
import Cake.LevelSpecific.Garden.WaterHose.WaterHoseComponent;
import Cake.LevelSpecific.Garden.Sickle.Enemy.SickleEnemyComponent;
import Vino.PlayerHealth.PlayerHealthStatics;
import Cake.LevelSpecific.Garden.GardenLevelScriptActor;
import Cake.LevelSpecific.Garden.Sickle.Enemy.SickleEnemyEffects;


void DeactivateDecal(ASickleEnemyEffectBloodDecal Decal)
{
	USickleComponent::Get(Game::GetMay()).DeactivateDecal(Decal);
}

struct FSickleAnimationTranslation
{
	float Amount = 0;
	float MoveSpeed = 0;
}

// Used for 
class ASickleTargetAttachment : AHazeActor
{
	default SetActorEnableCollision(false);

    UPROPERTY(DefaultComponent, RootComponent)
    USceneComponent Root;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SetActorTickEnabled(false);		
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		System::DrawDebugSphere(GetActorLocation(), Duration = 0.f);
	}
}

struct FSickleReplicatedImpact
{
	UPROPERTY()
	float DamageAmount = 0;

	UPROPERTY()
	TArray<USickleCuttableComponent> Targets;

	UPROPERTY()
	TArray<bool> Invulerable;

	UPROPERTY()
	FName ComboTag = NAME_None;

	UPROPERTY()
	TArray<FVector> ImpactDirections;

	void AddTarget(AHazePlayerCharacter Player, USickleCuttableComponent TargetComponent)
	{
		Targets.Add(TargetComponent);

		FVector OwnerLocation =  TargetComponent.GetOwner().GetActorLocation();
		FVector ImpactDirection = (OwnerLocation - Player.GetActorLocation()) * 0.1f;
		ImpactDirection.Normalize();

		ImpactDirections.Add(ImpactDirection);

		// Store if the target was invulerable at the moment
		Invulerable.Add(false);
		auto HealthComponent = Cast<USickleCuttableHealthComponent>(TargetComponent);
		if(HealthComponent != nullptr)
		{
			if(HealthComponent.GetInvulnerableStatus(Player))
				Invulerable[Invulerable.Num() - 1] = true;
		}
	}
}

struct FSickleImpactArc
{
	// If > 0, all enemies, not just the current target will be hit
	UPROPERTY()
	float Radius = 0;

	// Include enemies in an arc. 1 is 180 degrees to the left. 0 is only forward
	UPROPERTY(meta = (ClampMin = "0.0", ClampMax = "180.0", UIMin = "0.0", UIMax = "180.0"))
	float LeftAngle = 180;

	// Include enemies in an arc. 1 is 180 degrees to the right. 0 is only forward
	UPROPERTY(meta = (ClampMin = "0.0", ClampMax = "180.0", UIMin = "0.0", UIMax = "180.0"))
	float RightAngle = 180;
}

UCLASS(Abstract)
class USickleComponent : UActorComponent
{
	UPROPERTY(Category = "Player Lives")
	UPlayerHealthSettings HealthSettings = Asset("/Game/Blueprints/PlayerHealth/DA_HealthSettings_GardenCombat.DA_HealthSettings_GardenCombat");

	// How heigh above the ground we will make a ground attack
	UPROPERTY()
	float GroundMovesTraceDistance = 150.f;

	UPROPERTY()
    TSubclassOf<ASickle> SickleClass;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<ASickleEnemyEffectBloodDecal> SickleEnemyBloodDecalType;
	const int BloodDecalAmount = 10;

    UPROPERTY(BlueprintReadOnly)
	ASickle SickleActor;

	UPROPERTY(Transient, NotEditable)
	TArray<ASickleEnemyEffectBloodDecal> AvailableBloodDecals;

	UPROPERTY(Transient, NotEditable)
	TArray<ASickleEnemyEffectBloodDecal> BloodDecalsInUse;

	UPROPERTY(NotVisible)
	ASickleTargetAttachment SickleTargetAttachmentActor;

	UPROPERTY()
	UHazeLocomotionStateMachineAsset RelaxedAsset;

	UPROPERTY()
	ULocomotionSickleStateMachineAsset AlertedAsset;

	// Animations param
	UPROPERTY(BlueprintReadOnly)
	bool bIsCombat = false;

	// Animations param
	UPROPERTY(BlueprintReadOnly)
	bool bSickleIsEquiped = false;

	UPROPERTY(Category = "ForceFeedback")
	UForceFeedbackEffect MissEffect;

	UPROPERTY(Category = "ForceFeedback")
	UForceFeedbackEffect ImpactEffect;

	int IsAlertedCounter = 0;
	int ComboCurrent = 0;
 	USickleAttackDataAsset CurrentAttackAsset = nullptr;

	private APlayerCharacter Player;
	private float TimeLeftToResetComboIndex = 0.f;

	bool bCanActiveNextAttack = true;
	bool bBlockAttackUntilGrounded = false;
	bool bResetBlockOnNewTarget = false;
	bool bResetBlocksOnAirAction = false;

	//private bool bHasPendingImpact = false;
	private TArray<UObject> ActiveTrailEffectCounter;
	private int CombatIsEnabledCounter = 0;

	FSickleAnimationTranslation HorizontalTranslation;
	FSickleAnimationTranslation VerticleTranslation;

	//FHazeCrumbDelegate CrumbDelegate;
	float CurrentGroundTraceDistance = -1;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Player = Cast<APlayerCharacter>(Owner);
		
		SickleActor = Cast<ASickle>(SpawnPersistentActor(SickleClass));
		Player.OnHiddenInGameStatusChanged.AddUFunction(this, n"OnHiddenInGameStatusChanged");

		for(int i = 0; i < BloodDecalAmount; ++i)
		{
			auto BloodActor = Cast<ASickleEnemyEffectBloodDecal>(SpawnPersistentActor(SickleEnemyBloodDecalType));
			BloodActor.SetOwner(Player);
			BloodActor.DisableActor(Player);
			AvailableBloodDecals.Add(BloodActor);
		}

		// This is made in the SickleComboPerformCapability now to be able to use the waterhose
		// SickleActor.AttachToActor(Player, n"LeftAttach");
		// SickleActor.SetActorRelativeTransform(SickleActor.AttachTransform);

		SickleTargetAttachmentActor = Cast<ASickleTargetAttachment>(SpawnPersistentActor(ASickleTargetAttachment::StaticClass()));
		SickleTargetAttachmentActor.MakeNetworked(this, n"MaysSickleAttachment");
		SickleTargetAttachmentActor.SetControlSide(Player);
		SickleTargetAttachmentActor.SetOwner(Player);
		SetSickleOutline(true);

		//CrumbDelegate.BindUFunction(this, n"TriggerImpact");
	}

	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason Reason)
	{
		DisableCombat(Player);
		SetSickleOutline(false);
		ForceDisableTrail();

		if(SickleActor != nullptr)
		{
			SickleActor.DetachFromActor();
			SickleActor.DestroyActor();
			SickleActor = nullptr;
		}

		for(int i = 0; i < AvailableBloodDecals.Num(); ++i)
		{
			AvailableBloodDecals[i].DestroyActor();
		}
		AvailableBloodDecals.Reset();

		for(int i = 0; i < BloodDecalsInUse.Num(); ++i)
		{
			BloodDecalsInUse[i].DestroyActor();
		}
		BloodDecalsInUse.Reset();

		if(SickleTargetAttachmentActor != nullptr)
		{
			SickleTargetAttachmentActor.DestroyActor();
			SickleTargetAttachmentActor = nullptr;
		}

		Player.OnHiddenInGameStatusChanged.UnbindObject(this);
		//CrumbDelegate.Clear();
	}

	UFUNCTION(BlueprintOverride)
	void OnResetComponent(EComponentResetType ResetType)
	{
		ForceDisableTrail();
	}

	UFUNCTION(NotBlueprintCallable)
	void OnHiddenInGameStatusChanged(AHazeActor ThisPlayer, bool bHidden)
	{
		SickleActor.SetActorHiddenInGame(bHidden);
		ForceDisableTrail();
	}

	void EnableCombat(AHazePlayerCharacter ActivatingPlayer)
	{
		ActivatingPlayer.ApplySettings(HealthSettings, this);

		CombatIsEnabledCounter++;
		if(CombatIsEnabledCounter == 1)
		{		
			bIsCombat = true;
		}	

		if(ActivatingPlayer == Player)
		{
			EnableCombatStance(true);
		}
	}

	void DisableCombat(AHazePlayerCharacter ActivatingPlayer)
	{
		UPlayerHealthComponent ActiveHealthComp = UPlayerHealthComponent::Get(ActivatingPlayer); 

		if(ActiveHealthComp.CurrentHealth >= 1.f)
			ActivatingPlayer.ClearSettingsByInstigator(this);
		
		CombatIsEnabledCounter--;
		if(CombatIsEnabledCounter == 0)
		{
			bIsCombat = false;

			// Heal both players
			HealPlayerHealth(Player, 1.f);
			Player.ClearSettingsByInstigator(this);

			HealPlayerHealth(Player.GetOtherPlayer(), 1.f);
			Player.GetOtherPlayer().ClearSettingsByInstigator(this);
		}	

		if(ActivatingPlayer == Player)
		{
			DisableCombatStance();
		}
	}

	UFUNCTION()
	void EnableCombatStance(bool bPlayEquipAnimation)
	{
		IsAlertedCounter++;
		if(IsAlertedCounter == 1)
		{
			Player.StopOverrideAnimation(AlertedAsset.UnequipAnimation.Animation);
			Player.ClearLocomotionAssetByInstigator(this);
			Player.AddLocomotionAsset(AlertedAsset, this);

			// If we go into combat from a combat move, we snap the attachment
			if(bPlayEquipAnimation)
			{
				Player.PlayOverrideAnimation(FHazeAnimationDelegate(), AlertedAsset.EquipAnimation);
				Player.BindOrExecuteOneShotAnimNotifyDelegate(AlertedAsset.EquipAnimation.Animation, UAnimNotify_SickleAttach::StaticClass(), FHazeAnimNotifyDelegate(this, n"Notify_EquipSickle"));
			}
			else
			{
				Notify_EquipSickle(Player, Player.Mesh, nullptr);
			}
		}
	}

	UFUNCTION()
	void DisableCombatStance()
	{
		IsAlertedCounter--;
		if(IsAlertedCounter == 0)
		{
			Player.StopOverrideAnimation(AlertedAsset.EquipAnimation.Animation);
			Player.PlayOverrideAnimation(FHazeAnimationDelegate(), AlertedAsset.UnequipAnimation);
			Player.BindOrExecuteOneShotAnimNotifyDelegate(AlertedAsset.UnequipAnimation.Animation, UAnimNotify_SickleDetach::StaticClass(), FHazeAnimNotifyDelegate(this, n"Notify_UnequipSickle"));	
			Player.ClearLocomotionAssetByInstigator(this);
			Player.AddLocomotionAsset(RelaxedAsset, this);
		}
	}

	UFUNCTION(NotBlueprintCallable)
	void Notify_EquipSickle(AHazeActor Actor, UHazeSkeletalMeshComponentBase SkelMesh, UAnimNotify AnimNotify)
	{
		if(bSickleIsEquiped)
			return;

		bSickleIsEquiped = true;
		auto WaterComp = UWaterHoseComponent::Get(Actor);
		WaterComp.bSickleIsEqipped = true;
		Player.SetCapabilityActionState(n"AudioSickleEquip", EHazeActionState::ActiveForOneFrame);
		if(SickleActor != nullptr)
		{
			SickleActor.AttachToComponent(Player.Mesh, n"LeftAttach");
			SickleActor.OnAttachedToPlayer();
		}
	}

	UFUNCTION(NotBlueprintCallable)
	void Notify_UnequipSickle(AHazeActor Actor, UHazeSkeletalMeshComponentBase SkelMesh, UAnimNotify AnimNotify)
	{
		if(!bSickleIsEquiped)
			return;

		bSickleIsEquiped = false;
		auto WaterComp = UWaterHoseComponent::Get(Actor);
		WaterComp.bSickleIsEqipped = false;
		ForceDisableTrail();
		Player.SetCapabilityActionState(n"AudioSickleUnequip", EHazeActionState::ActiveForOneFrame);
		if(SickleActor != nullptr)
		{
			SickleActor.AttachToComponent(WaterComp.WaterHose.GetGunMesh(), n"LeftAttach");
			SickleActor.OnAttachedToWaterHose();
		}
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if(TimeLeftToResetComboIndex > 0 && CurrentAttackAsset == nullptr)
		{
			TimeLeftToResetComboIndex -= DeltaTime;
			if(TimeLeftToResetComboIndex <= 0)
			{
				ResetComboCounter();
			}
		}

		if(CurrentGroundTraceDistance < 50.f)
			CurrentGroundTraceDistance = -1;
		else if(Player.CharacterMovementComponent.IsGrounded())
			CurrentGroundTraceDistance = -1;
		
		if(bBlockAttackUntilGrounded 
			&& UHazeMovementComponent::Get(Player).IsGrounded())
		{
			bBlockAttackUntilGrounded = false;
			bResetBlockOnNewTarget = false;
			bResetBlocksOnAirAction = false;
		}

		if(bResetBlockOnNewTarget)
		{
			auto ActiveComponent = Cast<USickleCuttableComponent>(Player.GetActivePoint());
			auto TargetComponent = Cast<USickleCuttableComponent>(Player.GetTargetPoint(USickleCuttableComponent::StaticClass()));;
			if(TargetComponent != nullptr && ActiveComponent == nullptr)
			{
				bBlockAttackUntilGrounded = false;
				bResetBlocksOnAirAction = false;
				bResetBlockOnNewTarget = false;
			}
		}

		if(bResetBlocksOnAirAction)
		{
			if(Player.IsAnyCapabilityActive(MovementSystemTags::AirJump)
				|| Player.IsAnyCapabilityActive(MovementSystemTags::AirDash)
			)
			{
				bBlockAttackUntilGrounded = false;
				bResetBlocksOnAirAction = false;
				bResetBlockOnNewTarget = false;
			}
		}
	}

	float CalculateCurrentGroundTraceDistance()
	{
		if(CurrentGroundTraceDistance >= 0)
			return CurrentGroundTraceDistance;

		FHazeTraceParams Settings;
		Settings.InitWithMovementComponent(Player.CharacterMovementComponent);
		Settings.From = Player.GetActorCenterLocation();
		Settings.To = Settings.From - (Player.CharacterMovementComponent.WorldUp * GroundMovesTraceDistance);
		
		FHazeHitResult Hit;
		if(Settings.Trace(Hit))
		{
			const FHitResult ConvertedHit = Hit.FHitResult;
			CurrentGroundTraceDistance = ConvertedHit.Distance;
		}	
		else
		{
			CurrentGroundTraceDistance = GroundMovesTraceDistance;
		}
			
		return CurrentGroundTraceDistance;
	}

	bool GetDataAssetComboRequest(USickleCuttableComponent TargetComponent, int Request, USickleAttackDataAsset& OutDataAsset)
	{
		// OutData.TargetComponent = Cast<USickleCuttableComponent>(Player.GetActivePoint());
		// if(OutData.TargetComponent == nullptr)
		// {
		// 	OutData.TargetComponent = Cast<USickleCuttableComponent>(Player.GetTargetPoint(EHazeActivationPointIdentifierType::LevelSpecific));
		// }

		FSickleAttackValidationCompareData RequestData;


		// Initialize the request
		RequestData.WantedComboNumber = Request;

		if(CurrentAttackAsset != nullptr)
			RequestData.CurrentComboTag = CurrentAttackAsset.ComboTag;

		// Player stats
		const FMovementStateParams MoveState = Player.GetMovementState();
		RequestData.bPlayerIsGrounded = CalculateCurrentGroundTraceDistance() < GroundMovesTraceDistance;

		// Target stats
		if(TargetComponent != nullptr)
		{
			RequestData.bHasTarget = true;
			RequestData.TargetNameTag = TargetComponent.AttackTypeName;

			AHazeActor Target = Cast<AHazeActor>(TargetComponent.GetOwner());
			UHazeBaseMovementComponent TargetMoveComp = UHazeBaseMovementComponent::Get(Target);
			RequestData.bTargetIsGrounded = true;
			if(TargetComponent.GroundedType == ESickleTargetGroundedType::Default)
			{
				if(TargetMoveComp != nullptr)
				{
					RequestData.bTargetIsGrounded = TargetMoveComp.IsGrounded();
				}
			}
			if(TargetComponent.GroundedType == ESickleTargetGroundedType::InAir)
			{
				RequestData.bTargetIsGrounded = false;
			}

			// When doing combos, we use the thing we are attackings grounded state
			if(Request > 1)
			{
				RequestData.bPlayerIsGrounded = RequestData.bTargetIsGrounded;
			}

			RequestData.bTargetIsInvulerable = TargetComponent.GetInvulnerableStatus(Player);
			
			const FVector DirToTarget = (Target.GetActorLocation() - MoveState.Location).ConstrainToPlane(MoveState.WorldUp).GetSafeNormal();
			const FVector FacingDirection = MoveState.Rotation.Vector();
			RequestData.AngleToTarget = Math::DotToDegrees(FacingDirection.DotProduct(DirToTarget));
			RequestData.DistanceToTarget = FMath::Max(0.f, Target.GetHorizontalDistanceTo(Player) - (Player.GetCollisionSize().X + GetTargetCollisionSize(Target)));
		}

		if(AlertedAsset != nullptr)
		{
			TArray<USickleAttackDataAsset> FoundAssets;
			for(int i = 0; i < AlertedAsset.Attacks.Num(); ++i)
			{
				if(AlertedAsset.Attacks[i] != nullptr)
				{
					// We found a match
					if(AlertedAsset.Attacks[i].Validation.IsValidTo(RequestData))
					{
						FoundAssets.Add(AlertedAsset.Attacks[i]);
					}
				}
			}

			if(FoundAssets.Num() > 0)
			{
				OutDataAsset = GetBestAsset(FoundAssets);
				return true;
			}
		}

		return false;	
	}

	float GetTargetCollisionSize(AHazeActor Actor) const
	{
		AHazeCharacter Character = Cast<AHazeCharacter>(Actor);
		if(Character != nullptr)
		{
			return Character.GetCollisionSize().X;
		}		
		else
		{
			FVector Origin;
			FVector Bounds;
			Actor.GetActorBounds(true, Origin, Bounds);
			Bounds.Z = 0;
			return Bounds.Size(); 
		}		
	}

	USickleAttackDataAsset GetBestAsset(TArray<USickleAttackDataAsset> FoundAssets) const
	{
		int RequiredScore = 0;
		TArray<USickleAttackDataAsset> PrioAssets;
		for(int i = 0; i < FoundAssets.Num(); ++i)
		{
			USickleAttackDataAsset CurrentAsset = FoundAssets[i];
			if(CurrentAsset.Validation.bRequiresTarget)
			{
				int Score = 0;
				if(CurrentAsset.Validation.TargetData.bRequiresTargetAngle)
					Score++;
				
				if(CurrentAsset.Validation.TargetData.bRequiresTargetDistance)
					Score++;

				if(Score > RequiredScore)
				{
					RequiredScore = Score;
					PrioAssets.Empty();
					PrioAssets.Add(CurrentAsset);
				}
				else if(Score == RequiredScore)
				{
					PrioAssets.Add(CurrentAsset);
				}
			}
		}

		if(PrioAssets.Num() > 0)
		{
			return PrioAssets[FMath::RandRange(0, PrioAssets.Num() - 1)];
		}
		else
		{
			return FoundAssets[FMath::RandRange(0, FoundAssets.Num() - 1)];
		}		
	}

	void ResetActiveCombo()
	{
		if(CurrentAttackAsset != nullptr)
		{
			TimeLeftToResetComboIndex = CurrentAttackAsset.TimeBeforeComboCounterReset;		
		}
	}

	void TriggerPendingControlImpact(FSickleImpactArc ImpactArc, UObject Instigator, FName TriggerImpactFunctionName)
	{
		if(!Player.HasControl())
			return;

		if(CurrentAttackAsset == nullptr)
			return;

		FSickleReplicatedImpact ReplicatedImpactData;
		ReplicatedImpactData.DamageAmount = CurrentAttackAsset.GetDamage();
		ReplicatedImpactData.ComboTag = CurrentAttackAsset.ComboTag;

		USickleCuttableComponent TargetComponent = Cast<USickleCuttableComponent>(Player.GetActivePoint());
		if(ImpactArc.Radius > 0)
		{
			// DEBUG
			//System::DrawDebugCircle(Player.GetActorCenterLocation(), ImpactArc.Radius, 36, YAxis = FVector::RightVector, ZAxis = FVector::ForwardVector, Duration = 3.f, LineColor = FLinearColor::Red);

			// Validate all querries
		 	TArray<FHazeQueriedActivationPoint> ValidPoints;
		 	Player.QueryActivationPoints(USickleCuttableComponent::StaticClass(), ValidPoints);
		 	for(int i = 0; i < ValidPoints.Num(); ++i)
		 	{
				if(!ValidPoints[i].IsValid())
					continue;

		 		auto QueryPoint = Cast<USickleCuttableComponent>(ValidPoints[i].Point);
		 		if(ValidatePoint(QueryPoint, ImpactArc))
				{
					ReplicatedImpactData.AddTarget(Player, QueryPoint);
				}	 		
		 	}

			// Validate the current active point.
			if(ValidatePoint(TargetComponent, ImpactArc))
			{
				ReplicatedImpactData.AddTarget(Player, TargetComponent);
			}
		}
		else if(TargetComponent != nullptr)
		{
			// Having no impact arc is a garanteed impact to the current target
			ReplicatedImpactData.AddTarget(Player, TargetComponent);
		}

		if(ReplicatedImpactData.Targets.Num() == 0)
		{
			// DEBUG
			//ValidatePoint(TargetComponent, ImpactArc);
			Player.PlayForceFeedback(MissEffect, false, true, n"SickleMiss", 0.25f);
			return;
		}


		float IntensityAlpha = float(ReplicatedImpactData.Targets.Num()) / 5.f;
		IntensityAlpha = FMath::Clamp(IntensityAlpha, 0.25f, 1.f);
		Player.PlayForceFeedback(ImpactEffect, false, true, n"SickleHit", IntensityAlpha);
			
		FHazeCrumbDelegate CrumbDelegate;
		CrumbDelegate.BindUFunction(Instigator, TriggerImpactFunctionName);
			
		auto CrumbComp = UHazeCrumbComponent::Get(Player);
		FHazeDelegateCrumbParams Params;
		Params.AddStruct(n"ImpactData", ReplicatedImpactData);

		CrumbComp.LeaveAndTriggerDelegateCrumb(CrumbDelegate, Params);
	}

	bool ValidatePoint(USickleCuttableComponent QueryPoint, FSickleImpactArc ImpactArc) const
	{
		if(QueryPoint == nullptr)
			return false;

		const FVector PointPosition = QueryPoint.GetPlayerAttackPosition(Player);
		const FVector ActorPosition = Player.GetActorLocation();
		const FVector DirToPoint = (PointPosition - ActorPosition).GetSafeNormal();

		// To far
		const float Dist = PointPosition.Distance(ActorPosition);
		if(PointPosition.DistSquared(ActorPosition) > FMath::Square(ImpactArc.Radius))
			return false;

		const float RightDot = Player.GetActorRightVector().DotProduct(DirToPoint);
		float ValidAngle = 0;
		float CompareAngle = 0;
		if(RightDot >= 0)
		{
			ValidAngle = Math::DotToDegrees(Math::GetNormalizedDotProduct(Player.GetActorRightVector(), DirToPoint));
			CompareAngle = ImpactArc.RightAngle;
		}
		else
		{
			ValidAngle = Math::DotToDegrees(Math::GetNormalizedDotProduct(-Player.GetActorRightVector(), DirToPoint));
			CompareAngle = ImpactArc.LeftAngle;
		}

		if(ValidAngle > CompareAngle)
			return false;

		return true;
	}

	void ResetComboCounter()
	{
		TimeLeftToResetComboIndex = 0;
		ComboCurrent = 0;
	}

    void SetSickleOutline(bool bShow)
    {
        if (bShow)
            SickleActor.SickleMesh.AddMeshToPlayerOutline(Player, this);
        else if(SickleActor != nullptr)
            RemoveMeshFromPlayerOutline(SickleActor.SickleMesh, this);
    }

	void EnableTrail(UObject Instigator)
	{
		ActiveTrailEffectCounter.AddUnique(Instigator);
		if(ActiveTrailEffectCounter.Num() == 1)
			SickleActor.SetTrailEnabled(true);
	}

	void DisableTrail(UObject Instigator)
	{
		ActiveTrailEffectCounter.RemoveSwap(Instigator);
		if(ActiveTrailEffectCounter.Num() == 0)
			SickleActor.SetTrailEnabled(false);
	}

	void ForceDisableTrail()
	{
		ActiveTrailEffectCounter.Reset();
		SickleActor.SetTrailEnabled(false);
	}

	void EnableBloodDecal(FTransform ParentTransform)
	{
		auto DefaultBlood = Cast<ASickleEnemyEffectBloodDecal>(SickleEnemyBloodDecalType.Get().GetDefaultObject());
		FTransform RandomTransform = ParentTransform;
		FVector RandomOffset = FRotator(0.f, DefaultBlood.RandomAngle.GetRandomValue(), 0.f).Vector() * DefaultBlood.RandomOffset.GetRandomValue();
		RandomOffset = ParentTransform.TransformPosition(RandomOffset);
		RandomOffset += FVector::UpVector; // Add 1 so we dont clip the ground
	
		if(AvailableBloodDecals.Num() > 0)
		{
			// we add a new decal on the ground
			EnableAvailableDecal(RandomOffset);
		}
		else
		{
			// we move the oldest decal to the new location
			ReEnableInUseArray(RandomOffset);
		}
	}

	
	void EnableAvailableDecal(FVector Location)
	{
		const int Index = AvailableBloodDecals.Num() - 1;
		auto Decal = AvailableBloodDecals[Index];
		AvailableBloodDecals.RemoveAtSwap(Index);
		Decal.SetActorLocation(Location);
		Decal.EnableActor(Player);
		Decal.StartAndShowEffect();
		BloodDecalsInUse.Add(Decal);
	}

	void ReEnableInUseArray(FVector Location)
	{
		int BestIndex = 0;
		float BestGameTime = -1;

		// Find the oldest decal and re-use that
		for(int i = 0; i < BloodDecalsInUse.Num(); ++i)
		{
			if(BloodDecalsInUse[i].ActivationGameTime < BestGameTime)
				continue;

			BestGameTime = BloodDecalsInUse[i].ActivationGameTime;
			BestIndex = i;
		}

		auto Decal = BloodDecalsInUse[BestIndex];
		Decal.SetActorLocation(Location);
		Decal.StartAndShowEffect();
	}

	void DeactivateDecal(ASickleEnemyEffectBloodDecal Decal)
	{
		Decal.EndAndHideEffect();
		Decal.DisableActor(Player);
		BloodDecalsInUse.RemoveSwap(Decal);
		AvailableBloodDecals.Add(Decal);
	}
}
