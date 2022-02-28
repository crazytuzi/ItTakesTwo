import Vino.Trajectory.TrajectoryStatics;
import Vino.Projectile.ProjectileMovement;
import Vino.PlayerHealth.PlayerHealthStatics;
import Vino.PlayerHealth.PlayerHealthComponent;
import Vino.Camera.Components.WorldCameraShakeComponent;
import Vino.Movement.Capabilities.KnockDown.KnockdownStatics;

event void FOnDebrisLanded(AVacuumBossDebris Debris);

UCLASS(Abstract)
class AVacuumBossDebris : AHazeActor
{
    UPROPERTY(DefaultComponent, RootComponent)
    UStaticMeshComponent Mesh;
    default Mesh.LightmapType = ELightmapType::ForceVolumetric;
    default Mesh.CollisionProfileName = n"OverlapAllDynamic";

	UPROPERTY(DefaultComponent, Attach = Mesh)
	UDecalComponent DangerZoneDecal;

	UPROPERTY(DefaultComponent, Attach = DangerZoneDecal)
	UForceFeedbackComponent ForceFeedbackComp;

	UPROPERTY(DefaultComponent, Attach = DangerZoneDecal)
	UWorldCameraShakeComponent CamShakeComp;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent DebrisLandAudioEvent;

	UPROPERTY(Category = "Audio Events")
    float ExplosionVolumeOffset = -10.f;

    UPROPERTY()
    bool bBeingLaunched = false;

	UPROPERTY(NotEditable)
    FVector TargetLocation;

    UPROPERTY()
    float MovementSpeed = 0.75f;

    FOnDebrisLanded OnDebrisLanded;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<UPlayerDamageEffect> PlayerDamageEffect;

	UPROPERTY(EditDefaultsOnly)
	UNiagaraSystem ImpactEffect;

	UPROPERTY(EditDefaultsOnly)
	UCurveFloat DangerZoneTimeCurve;
	
    FProjectileMovementData ProjectileMovementData;

	UMaterialInstanceDynamic DecalMaterialInstance;

	float LaunchTime = 0.f;

    UFUNCTION(BlueprintOverride)
    void BeginPlay()
    {
		SetActorTickEnabled(false);
		DangerZoneDecal.DetachFromComponent(EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld);
		DangerZoneDecal.SetWorldRotation(FRotator(90.f, 0.f, 0.f));
    }

	void LaunchDebris(FVector StartLoc, FVector TargetLoc)
	{
		SetActorTickEnabled(true);
		TargetLocation = TargetLoc;

		FVector Velocity = CalculateVelocityForPathWithHeight(StartLoc, TargetLocation, 980.f, 600.f);
		ProjectileMovementData.Velocity = Velocity;

		LaunchTime = 0.f;

		float RandomYaw = FMath::RandRange(0.f, 360.f);
		float RandomRoll = FMath::RandRange(0.f, 360.f);
		TeleportActor(StartLoc, FRotator(0.f, RandomYaw, RandomRoll));
		SetActorHiddenInGame(false);
		SetActorEnableCollision(true);

		bBeingLaunched = true;

		DangerZoneDecal.SetRelativeScale3D(0.f);
		DangerZoneDecal.SetWorldLocation(TargetLocation);
		DangerZoneDecal.SetHiddenInGame(false);
	}

    UFUNCTION(BlueprintOverride)
    void Tick(float Delta)
    {
		if(bBeingLaunched)
        {
            FProjectileUpdateData UpdateData = CalculateProjectileMovement(ProjectileMovementData, Delta * 2.5f);
            ProjectileMovementData = UpdateData.UpdatedMovementData;

            FHitResult HitResult;
            AddActorWorldOffset(UpdateData.DeltaMovement, true, HitResult, false);
			AddActorLocalRotation(FRotator(0.f, 280.f, 0.f) * Delta);
			
			LaunchTime += Delta;
			float DecalScale = FMath::Lerp(0.f, 1.f, LaunchTime * 2.f);
			DecalScale = FMath::Clamp(DecalScale, 0.f, 1.f);
			DangerZoneDecal.SetRelativeScale3D(DecalScale);

            if (HitResult.bBlockingHit)
			{
				AHazePlayerCharacter Player;
				if (HitResult.Actor != nullptr)
					Player = Cast<AHazePlayerCharacter>(HitResult.Actor);
				if (Player != nullptr)
				{
					DamagePlayerHealth(Player, 0.5f,PlayerDamageEffect);
					FVector DirToPlayer = Player.ActorLocation - ActorLocation;
					DirToPlayer = Math::ConstrainVectorToPlane(DirToPlayer, FVector::UpVector);
					DirToPlayer.Normalize();
					KnockdownActor(Player, (DirToPlayer * 1400.f) + FVector(0.f, 0.f, 1250.f));
				}
                DebrisLanded();
			}
        }
    }

    void DebrisLanded()
    {
        bBeingLaunched = false;

		ForceFeedbackComp.Play();
		CamShakeComp.Play();

		TMap<FString, float> Rtpcs;
		Rtpcs.Add("Rtpc_Gameplay_Explosions_Shared_VolumeOffset", ExplosionVolumeOffset);
		UHazeAkComponent::HazePostEventFireForget(DebrisLandAudioEvent, this.GetActorTransform());
		UHazeAkComponent::HazePostEventFireForgetWithRtpcs(DebrisLandAudioEvent, this.GetActorTransform(), Rtpcs);

        OnDebrisLanded.Broadcast(this);
		Niagara::SpawnSystemAtLocation(ImpactEffect, DangerZoneDecal.WorldLocation);
		SetActorHiddenInGame(true);
		SetActorEnableCollision(false);
		SetActorTickEnabled(false);
		DangerZoneDecal.SetHiddenInGame(true);
    }
}