import Cake.LevelSpecific.Clockwork.Fireworks.FireworkRocket;
import Vino.Interactions.InteractionComponent;
import Vino.PlayerHealth.PlayerHealthStatics;

event void FEventDissipateActor(AFireworkRocket Rocket);
event void FFireworkExploded(AHazePlayerCharacter Player);

class AFireworkStation : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent MeshCompBase;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent MeshCompCannon;

	UPROPERTY(DefaultComponent, Attach = MeshCompCannon)
	USceneComponent SpawnLoc;

	UPROPERTY(DefaultComponent)
	UHazeAkComponent AkComp;

	UPROPERTY(DefaultComponent, Attach = Root)
	UNiagaraComponent MuzzleFlashSystem;
	default MuzzleFlashSystem.SetAutoActivate(false);

	UPROPERTY(DefaultComponent, Attach = Root)
	UNiagaraComponent MuzzleFlashSystemAlternate;
	default MuzzleFlashSystem.SetAutoActivate(false);

	UPROPERTY(DefaultComponent)
	UHazeDisableComponent DisableComponent;
	default DisableComponent.bAutoDisable = true;
	default DisableComponent.AutoDisableRange = 10000.f;

	UPROPERTY(Category = "Setup")
	AActor EndLoc;

	UPROPERTY(Category = "Audio")
	UAkAudioEvent FireworksFired;

	FFireworkExploded OnFireworkeExplodedEvent;

	float Timer;

	bool bCanTimer;
	bool bCannonReacting;
	bool bUserAlternateMuzzle;

	FVector StartLocation;
	FVector DownLoc;

	UPROPERTY()
	float CullDistanceMultiplier = 1.0f;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		MeshCompBase.SetCullDistance(Editor::GetDefaultCullingDistance(MeshCompBase) * CullDistanceMultiplier);
		MeshCompCannon.SetCullDistance(Editor::GetDefaultCullingDistance(MeshCompCannon) * CullDistanceMultiplier);
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		StartLocation = MeshCompCannon.WorldLocation;
		DownLoc = MeshCompCannon.WorldLocation + (MeshCompCannon.UpVector * -80.f);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (!bCanTimer)
			return;

		Timer -= DeltaTime;

		if (Timer <= 0.f)
		{
			OnFireworkeExplodedEvent.Broadcast(nullptr);
			bCanTimer = false;
		}
	}

	UFUNCTION(BlueprintEvent)
	void OnRocketActivated(UInteractionComponent InteractComp = nullptr, AHazePlayerCharacter Player = nullptr)
	{
		Timer = 2.5f;
		bCanTimer = true;
		bCannonReacting = true;
	}

	UFUNCTION()
	void InitateRocketFeedback()
	{
		AkComp.HazePostEvent(FireworksFired);

		if (bUserAlternateMuzzle)
			MuzzleFlashSystemAlternate.Activate();
		else
			MuzzleFlashSystem.Activate();

		bUserAlternateMuzzle = !bUserAlternateMuzzle;
	}
}