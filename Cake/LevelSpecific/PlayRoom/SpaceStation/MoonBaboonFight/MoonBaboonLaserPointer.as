import Vino.PlayerHealth.PlayerHealthStatics;
import Vino.PlayerHealth.PlayerHealthAudioComponent;
import Cake.LevelSpecific.PlayRoom.SpaceStation.MoonBaboonFight.MoonBaboonPowerCore;
import Peanuts.Audio.AudioStatics;
import Cake.LevelSpecific.PlayRoom.SpaceStation.ChangeSize.CharacterChangeSizeComponent;

event void FLaserPointerEvent();

UCLASS(Abstract)
class AMoonBaboonLaserPointer : AHazeActor
{
	UPROPERTY(RootComponent, DefaultComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent LaserRoot;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UNiagaraComponent ImpactEffect;

	UPROPERTY()
	EHazePlayer PlayerTarget;

	AHazePlayerCharacter PlayerToFollow;

	UPROPERTY()
	bool bEnabled = false;

	UPROPERTY()
	TSubclassOf<UPlayerDamageEffect> DamageEffect;

	UPROPERTY()
	TSubclassOf<UPlayerDeathEffect> DeathEffect;

	UPROPERTY()
	FLaserPointerEvent OnLaserPointerDisabled;

	UPROPERTY()
	FLaserPointerEvent OnPowerCoreDestroyed;

	UPROPERTY(EditDefaultsOnly)
	UNiagaraSystem LaserEffect;
	UNiagaraComponent CurLaserEffect;

	float InterpSpeed = 3.f;

	FVector TraceStartLocation;
	FVector TargetLocation;
	FVector CurrentLaserDir;

	bool bScalingDown = false;
	float CurrentScale = 1.f;

	float FollowSpeedMultiplier = 0.f;

	UPROPERTY(NotEditable)
	FVector CurrentImpactLocation;

	UPROPERTY()
	TArray<AActor> ActorsToIgnore;

	UPROPERTY()
	TArray<AActor> DirectionActorsToIgnore;

	UPROPERTY(DefaultComponent, Attach = LaserPointerNozzle)
	UHazeAkComponent LaserNozzleHazeAkComp;

	UPROPERTY(DefaultComponent)
	UHazeAkComponent LaserImpactHazeAkComp;
	default LaserImpactHazeAkComp.SetTrackDistanceToPlayer(true, MaxRadius = 1500.f);

	UPROPERTY()
	FHazeAudioEventInstance LaserNozzleEventInstance;

	UPROPERTY()
	FHazeAudioEventInstance LaserImpactEventInstance;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent LaserPointerChargeUpEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent StartLaserPointerNozzleLoopingEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent StopLaserPointerNozzleLoopingEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent StartLaserPointerImpactLoopingEvent;	

	default PrimaryActorTick.bStartWithTickEnabled = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		UpdateTarget(PlayerTarget);
		TargetLocation = ActorLocation;

		ImpactEffect.DetachFromParent(true);

		if (bEnabled)
			SetActorTickEnabled(true);
	}

	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason EndPlayReason)
	{
		if (CurLaserEffect != nullptr)
		{
			CurLaserEffect.Deactivate();
		}
	}

	void IgnorePlayer(AHazePlayerCharacter Player)
	{
		DirectionActorsToIgnore.Add(Player);
	}

	void UnignorePlayer(AHazePlayerCharacter Player)
	{
		DirectionActorsToIgnore.Remove(Player);
	}

	UFUNCTION()
	void UpdateTarget(EHazePlayer Player)
	{
		PlayerTarget = Player;
		if (Player == EHazePlayer::May)
			PlayerToFollow = Game::GetMay();
		else
			PlayerToFollow = Game::GetCody();
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (bEnabled)
		{
			AHazePlayerCharacter TargetPlayer = PlayerToFollow;
			if (TargetPlayer.IsPlayerDead())
				TargetPlayer = PlayerToFollow.OtherPlayer;

			FVector PlayerVelocity = TargetPlayer.GetActualVelocity();
			PlayerVelocity = Math::ConstrainVectorToPlane(PlayerVelocity, FVector::UpVector);
			FollowSpeedMultiplier += 0.25f * DeltaTime;
			FollowSpeedMultiplier = FMath::Clamp(FollowSpeedMultiplier, 0.f, 1.f);
			float PredictionMultiplier = PlayerVelocity.Size() * FollowSpeedMultiplier;
			PredictionMultiplier = FMath::Clamp(PredictionMultiplier, 0.f, 275.f);

			FVector PredictedPlayerLocation = TargetPlayer.ActorLocation + (TargetPlayer.MovementWorldUp * 88.f);
			PredictedPlayerLocation += TargetPlayer.ActorForwardVector * PredictionMultiplier;

			FVector DirToPlayer = PredictedPlayerLocation - TraceStartLocation;
			DirToPlayer = DirToPlayer.GetSafeNormal();
			FVector CurLocation = TraceStartLocation + (DirToPlayer * 10000.f);

			if (!bScalingDown)
				TargetLocation = FMath::VInterpTo(TargetLocation, CurLocation, DeltaTime, InterpSpeed);

			UCharacterChangeSizeComponent ChangeSizeComp = UCharacterChangeSizeComponent::Get(TargetPlayer);
			if (ChangeSizeComp != nullptr)
			{
				if (ChangeSizeComp.CurrentSize == ECharacterSize::Small)
					TargetLocation = TargetPlayer.ActorLocation;
			}

			FHitResult DirectionHit;
			System::LineTraceSingle(TraceStartLocation, TargetLocation, ETraceTypeQuery::Visibility, false, DirectionActorsToIgnore, EDrawDebugTrace::None, DirectionHit, true);

			CurLaserEffect.SetNiagaraVariableVec3("User.BeamStart", ActorLocation);

			if (DirectionHit.bBlockingHit)
			{
				CurrentImpactLocation = DirectionHit.Location;
				CurLaserEffect.SetNiagaraVariableVec3("User.BeamEnd", DirectionHit.Location);
				AMoonBaboonPowerCore PowerCore = Cast<AMoonBaboonPowerCore>(DirectionHit.Actor);

				if (PowerCore != nullptr && DirectionHit.Component == PowerCore.PowerCoreCollision && PowerCore.bCoreFullyExposed && !PowerCore.bDestroyed)
				{
					if (PlayerToFollow.HasControl())
						NetPowerCoreDestroyed(PowerCore);
				}

				AHazePlayerCharacter HitPlayer = Cast<AHazePlayerCharacter>(DirectionHit.Actor);

				if (HitPlayer != nullptr)
				{
					float Damage = 1.f/12.f;
					HitPlayer.DamagePlayerHealth(Damage, DamageEffect, DeathEffect);
					UPlayerHealthAudioComponent PlayerHealthAudioComp = UPlayerHealthAudioComponent::Get(HitPlayer);

					if(PlayerHealthAudioComp != nullptr)
					{
						PlayerHealthAudioComp.StartConstantDamage();
					}
				}
			}
			else
			{
				CurrentImpactLocation = DirectionHit.TraceEnd;
				CurLaserEffect.SetNiagaraVariableVec3("User.BeamEnd", DirectionHit.TraceEnd);
			}

			LaserImpactHazeAkComp.SetWorldLocation(CurrentImpactLocation);
		}

		if (bScalingDown)
		{
			CurrentScale -= 2.f * DeltaTime;
			CurrentScale = Math::Saturate(CurrentScale);
			CurLaserEffect.SetFloatParameter(n"User.Size", CurrentScale);
			if (CurrentScale <= 0)
			{			
				bScalingDown = false;
				bEnabled = false;
				CurLaserEffect.Deactivate();
				SetActorHiddenInGame(true);
			}
		}

		ImpactEffect.SetWorldLocation(CurrentImpactLocation);

		if (!bScalingDown && !bEnabled)
			SetActorTickEnabled(false);
	}

	UFUNCTION(NetFunction)
	void NetPowerCoreDestroyed(AMoonBaboonPowerCore PowerCore)
	{
		OnPowerCoreDestroyed.Broadcast();
		PowerCore.DestroyPowerCore();
		DisableLaserPointer();
		PowerCore.PowerCoreCollision.SetCollisionEnabled(ECollisionEnabled::NoCollision);
	}

	UFUNCTION()
	void ChargeUpLaserPointer()
	{
		if(LaserPointerChargeUpEvent != nullptr)
		{
			LaserNozzleEventInstance = LaserNozzleHazeAkComp.HazePostEvent(LaserPointerChargeUpEvent);
		}
	}

	UFUNCTION()
	void EnableLaserPointer()
	{
		CurLaserEffect = Niagara::SpawnSystemAtLocation(LaserEffect, ActorLocation);
		TargetLocation = ActorLocation;
		bEnabled = true;
		SetActorHiddenInGame(false);
		SetActorTickEnabled(true);
		ImpactEffect.Activate(true);

		if(StartLaserPointerNozzleLoopingEvent != nullptr)
		{
			LaserNozzleHazeAkComp.HazePostEvent(StartLaserPointerNozzleLoopingEvent);
		}

		if(StartLaserPointerImpactLoopingEvent != nullptr)
		{
			LaserImpactHazeAkComp.HazePostEvent(StartLaserPointerImpactLoopingEvent);
		}
	}

	UFUNCTION()
	void DisableLaserPointer()
	{
		CurrentScale = 1.f;
		FollowSpeedMultiplier = 0.f;
		bScalingDown = true;
		SetActorTickEnabled(true);
		OnLaserPointerDisabled.Broadcast();
		ImpactEffect.Deactivate();

		if(StopLaserPointerNozzleLoopingEvent != nullptr)
		{
			LaserNozzleHazeAkComp.HazePostEvent(StopLaserPointerNozzleLoopingEvent);
		}		
	}
}