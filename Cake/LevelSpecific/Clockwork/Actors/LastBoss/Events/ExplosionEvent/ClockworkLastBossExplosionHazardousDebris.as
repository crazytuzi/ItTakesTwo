import Cake.LevelSpecific.Clockwork.Actors.LastBoss.Events.ExplosionEvent.ClockworkLastBosExplosionDebrisStatics;
import Vino.Movement.Components.ImpactCallback.ActorImpactedCallbackComponent;
import Vino.PlayerHealth.PlayerHealthStatics;

class AClockworkLastBossExplosionHazardousDebris : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MeshRoot;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UStaticMeshComponent Mesh;

	UPROPERTY(DefaultComponent)
	UActorImpactedCallbackComponent Impacts;

	UPROPERTY()
	EDebrisType DebrisType = EDebrisType::A;

	UPROPERTY()
	TArray<UStaticMesh> MeshArray;

	UPROPERTY()
	TSubclassOf<UPlayerDeathEffect> DeathEffect;

	float ScrubValue = 0.f;

	UPROPERTY()
	float RollRotValue = -100.f;

	UPROPERTY()
	float PitchRotValue = 15.f;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Impacts.OnActorDownImpactedByPlayer.AddUFunction(this, n"PlayerLandedOnDebris");
		Impacts.OnActorForwardImpactedByPlayer.AddUFunction(this, n"PlayerLandedOnDebris");
		Impacts.OnActorUpImpactedByPlayer.AddUFunction(this, n"PlayerLandedOnDebris");
	}

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		int EnumNumber = DebrisType;
		if (EnumNumber > MeshArray.Num() - 1)
			DebrisType = EDebrisType::A;
			
		Mesh.SetStaticMesh(MeshArray[DebrisType]);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		MeshRoot.SetRelativeRotation(FRotator(FMath::Sin(ScrubValue) * PitchRotValue, 0.f, RollRotValue * ScrubValue));
	}

	UFUNCTION()
	void PlayerLandedOnDebris(AHazePlayerCharacter Player, const FHitResult& Hit)
	{
		KillPlayer(Player, DeathEffect);
	}

	UFUNCTION()
	void CurrentScrubValue(float NewScrubValue)
	{
		ScrubValue = NewScrubValue;
	}
}