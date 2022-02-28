import Cake.LevelSpecific.SnowGlobe.SnowballFight.SnowballFightProjectile;
import Cake.LevelSpecific.SnowGlobe.SnowballFight.SnowballFightCrosshairWidget;
import Peanuts.Aiming.AutoAimTarget;
import Vino.Trajectory.TrajectoryStatics;
import Vino.Interactions.AnimNotify_Interaction;
import Peanuts.Animation.Features.SnowGlobe.LocomotionFeatureSnowBallThrow;
import Peanuts.Animation.AnimationStatics;
import Vino.Movement.Grinding.UserGrindComponent;
import Vino.Tutorial.TutorialPrompt;
import Vino.Tutorial.TutorialStatics;
import Cake.LevelSpecific.SnowGlobe.SnowballFight.SnowballFightNames;

class USnowballFightComponent : UActorComponent
{
	default PrimaryComponentTick.bStartWithTickEnabled = false;

	UPROPERTY()
	TSubclassOf<ASnowballFightProjectile> ProjectileClass;
	UPROPERTY()
	TPerPlayer<ULocomotionFeatureSnowBallThrow> ThrowLocomotionFeatures;
	UPROPERTY()
	TPerPlayer<UAnimSequence> HitAnimations;
	UPROPERTY()
	UForceFeedbackEffect HitRumble;
	UPROPERTY()
	int PoolSize = 10;
	UPROPERTY()
	int MaxSnowballAmount = 5;
	UPROPERTY()
	float Cooldown = 0.75f;
	// For how long the player is in "hit"-state after taking damage
	UPROPERTY()
	float HitTime = 0.75f;
	UPROPERTY()
	FVector ProjectileSpawnOffset = FVector(0.f, 0.f, 100.f);
	UPROPERTY()
	float ThrowPower = 1.0f;
	UPROPERTY()
	float MaxRange = 8000.f;
	UPROPERTY()
	float LaunchDelay = 0.22f;
	UPROPERTY()
	float GraceDuration = 1.f;

	UPROPERTY(Category = "Camera")
	UHazeCameraSpringArmSettingsDataAsset AimCameraSettings;

	UPROPERTY(Category = "Widget")
	TSubclassOf<USnowballFightCrosshairWidget> CrosshairWidgetClass;

	UPROPERTY(Category = "AudioEvents")
	UAkAudioEvent SnowBallImpactAudioEvent;
	UPROPERTY(Category = "AudioEvents")
	UAkAudioEvent NoSnowBallAudioEvent;
	UPROPERTY(Category = "AudioEvents")
	UFoghornBarkDataAsset MayHitReactionVO;
	UPROPERTY(Category = "AudioEvents")
	UFoghornBarkDataAsset CodyHitReactionVO;

	UPROPERTY(Category = "VOBank")
	UFoghornVOBankDataAssetBase VOLevelBank;

	AHazePlayerCharacter Player;
	int CurrentSnowballAmount;
	bool bIsAiming;
	bool bMaxRangeAim;
	bool bIsWithinCollision;
	FVector AimTarget;
	FVector TargetRelativeLocation;
	FVector ProjectileSpawnLocation;
	USceneComponent AimTargetComponent;

	UAutoAimTargetComponent AutoAimTargetComponent;
	USnowballFightCrosshairWidget AimWidget;
	UUserGrindComponent GrindComp;

	int NumSpawnedProjectiles = 0;
	TArray<ASnowballFightProjectile> ProjectilePool;
	ASnowballFightProjectile HeldProjectile;

	// We need to know if we've added both (default/active) capability sheets to the player from a lot of different actors
	// we can check default by looking for this component, but we don't have a nice way of checking for
	// the active sheets; hence this cursed bool
	bool bHasActiveSheet;
	
	private float CooldownEnd;

	//*** TUTORIAL ***//
	UPROPERTY(Category = "Prompts")
	FTutorialPrompt LeftToAim;
	default LeftToAim.Action = ActionNames::SecondaryLevelAbility;

	UPROPERTY(Category = "Prompts")
	FTutorialPrompt RightToThrow;
	default RightToThrow.Action = ActionNames::PrimaryLevelAbility;

	UPROPERTY()
	UForceFeedbackEffect ThrowForceFeedback;

	bool bHaveCompletedTutorial;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Player = Cast<AHazePlayerCharacter>(Owner);

		AutoAimTargetComponent = UAutoAimTargetComponent::GetOrCreate(Player);
		AutoAimTargetComponent.RelativeLocation = FVector::UpVector * (Player.CapsuleComponent.CapsuleHalfHeight + 20.f);
		AutoAimTargetComponent.TargetRadius = 0.f;
		AutoAimTargetComponent.AutoAimMaxAngle = 12.5f;
		AutoAimTargetComponent.ChangeAffectedPlayers(Player.IsMay() ? EHazeSelectPlayer::Cody : EHazeSelectPlayer::May);

		GrindComp = UUserGrindComponent::Get(Owner);

		if (!ProjectileClass.IsValid())
			return;

		for (int i = 0; i < PoolSize; ++i)
		{
			auto Projectile = Cast<ASnowballFightProjectile>(SpawnActor(ProjectileClass, Level = Owner.Level));

			if (Projectile == nullptr)
				return;

			Projectile.MakeNetworked(this, NumSpawnedProjectiles++);
			Projectile.SetControlSide(Owner);
			Projectile.Deactivate(true);

			ProjectilePool.Add(Projectile);
		}
	}

	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason EndPlayReason)
	{
		Player.RemoveLocomotionFeature(ThrowLocomotionFeatures[Player.Player]);
		DestroyComponent(AutoAimTargetComponent);

		for (int i = 0; i < ProjectilePool.Num(); ++i)
		{
			if (ProjectilePool[i] != nullptr && !ProjectilePool[i].IsActorBeingDestroyed())
				ProjectilePool[i].DestroyActor();
		}
	}
	
	bool Throw(ASnowballFightProjectile Projectile)
	{
		if (Projectile == nullptr)
			return false;

		if (!HasAmmo())
		{
			AimWidget.PlayNoAmmoWobble();
			Player.PlayerHazeAkComp.HazePostEvent(NoSnowBallAudioEvent, 
				n"NoSnowBallAudioEvent");
			
			return false;
		}

		FName AttachSocketName;
		UAnimSequence ThrowAnimation;
		GetThrowAnimationAndSocket(Player, ThrowAnimation, AttachSocketName);

		FHazePlayOverrideAnimationParams Params;
		Params.BlendOutTime = 0.4f;
		Params.bMeshSpaceRotationBlend = GrindComp.HasActiveGrindSpline();
		Params.BoneFilter = EHazeBoneFilterTemplate::BoneFilter_UpperBody;
		Params.BlendTime = 0.06f;
		Params.Animation = ThrowAnimation;
		Player.PlayOverrideAnimation(FHazeAnimationDelegate(), Params);

		HeldProjectile = Projectile;
		HeldProjectile.Activate(Player, AttachSocketName);
		HeldProjectile.OnSnowballHit.AddUFunction(this, n"HandleSnowballHitOther");

		CurrentSnowballAmount--;

		if(AimWidget != nullptr)
			AimWidget.UpdateAmmo(CurrentSnowballAmount, false);

		CooldownEnd = Time::GameTimeSeconds + Cooldown;
		return true;
	}

	bool Launch(const FSnowballFightTargetData& TargetData, FVector LaunchLocation)
	{
		if (HeldProjectile == nullptr)
			return false;

		HeldProjectile.Launch(MaxRange, LaunchLocation, TargetData);
		HeldProjectile = nullptr;
		return true;
	}

	UFUNCTION()
	void RefillSnowballs()
	{
		CurrentSnowballAmount = MaxSnowballAmount;

		if(AimWidget != nullptr)
			AimWidget.UpdateAmmo(CurrentSnowballAmount, false);
	}

	UFUNCTION(BlueprintPure)
	bool HasAmmo() const
	{
		return CurrentSnowballAmount > 0;
	}

	UFUNCTION(BlueprintPure)
	bool HasCooldown() const
	{
		return Time::GameTimeSeconds < CooldownEnd;
	}

	private void GetThrowAnimationAndSocket(AHazePlayerCharacter Player,
		UAnimSequence&out ThrowAnimation, FName&out AttachSocketName) const
	{
		auto ThrowFeature = ThrowLocomotionFeatures[Player.Player];
		const float AimValue = GetHorizontalAimSpaceValue(Player);

		if (FMath::Abs(AimValue) < 0.25f)
		{
			ThrowAnimation = ThrowFeature.ThrowForward;
			AttachSocketName = n"RightAttach";
		}
		else if (FMath::Abs(AimValue) > 0.7f)
		{
			ThrowAnimation = ThrowFeature.ThrowBackRight;
			
			if(AimValue < 0.f)
			{
				ThrowAnimation = ThrowFeature.ThrowBackLeft;
				AttachSocketName = n"LeftAttach";
			}
			else
			{
				ThrowAnimation = ThrowFeature.ThrowBackRight;
				AttachSocketName = n"RightAttach";
			}
		}
		else if (AimValue < 0)
		{
			ThrowAnimation = ThrowFeature.ThrowLeft;
			AttachSocketName = n"RightAttach";
		}
		else
		{
			ThrowAnimation = ThrowFeature.ThrowRight;
			AttachSocketName = n"LeftAttach";
		}
	}

	int GetNextProjectileIndex()
	{
		// TODO: Use least relevant
		for (int i = 0; i < ProjectilePool.Num(); ++i)
		{
			auto Projectile = ProjectilePool[i];

			if (Projectile.IsActorDisabled())
				return i;
		}

		return -1;
	}

	ASnowballFightProjectile GetProjectileByIndex(int Index)
	{
		if (Index < 0 || Index >= ProjectilePool.Num())
			return nullptr;
		
		return ProjectilePool[Index];
	}

	UFUNCTION()
	void ShowLeftPrompt(AHazePlayerCharacter Player)
	{
		ShowTutorialPrompt(Player, LeftToAim, this);
	}

	UFUNCTION()
	void ShowRightPrompt(AHazePlayerCharacter Player)
	{
		ShowTutorialPrompt(Player, RightToThrow, this);
	}

	UFUNCTION()
	void RemovePrompts(AHazePlayerCharacter Player)
	{
		RemoveTutorialPromptByInstigator(Player, this);
	}

	// NOTE: Called when a snowball of ours hits an object; _not_ the event from our response comp
	// two events exist with the "OnSnowballHit" name, so... yeah
	UFUNCTION()
	private void HandleSnowballHitOther(FHitResult Hit)
	{
		if (Player == nullptr || VOLevelBank == nullptr)
			return;

		auto HitPlayer = Cast<AHazePlayerCharacter>(Hit.Actor);

		if (HitPlayer != nullptr)
		{
			FName EventName = Player.IsMay() ? 
				n"FoghornDBSnowGlobeTownSnowballsHitTauntMay" :
				n"FoghornDBSnowGlobeTownSnowballsHitTauntCody";

			PlayFoghornVOBankEvent(VOLevelBank, EventName);
		}
		else
		{
			auto SnowFolk = Cast<ASnowfolkSplineFollower>(Hit.Actor);

			if (SnowFolk == nullptr)
				return;

			FName EventName = Player.IsMay() ? 
				n"FoghornDBSnowGlobeTownSnowballsHitReactionOtherMay" :
				n"FoghornDBSnowGlobeTownSnowballsHitReactionOtherCody";

			PlayFoghornVOBankEvent(VOLevelBank, EventName);
		}
	}
};