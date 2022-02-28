import Vino.PlayerHealth.PlayerHealthComponent;
import Vino.PlayerHealth.PlayerHealthStatics;

UCLASS(Abstract)
class ALaserPropeller : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UStaticMeshComponent PropellerMesh;

	UPROPERTY(DefaultComponent)
	URotatingMovementComponent RotComp;

	UPROPERTY(DefaultComponent)
	UHazeAkComponent HazeAkComp;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent StartLaserAudioEvent;

	UPROPERTY(DefaultComponent)
	UHazeDisableComponent DisableComponent;
	default DisableComponent.bAutoDisable = true;
	default DisableComponent.AutoDisableRange = 6000.f;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<UPlayerDeathEffect> DeathEffect;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		HazeAkComp.HazePostEvent(StartLaserAudioEvent);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		// ASSUMPTION: Only Cody interacts with these in the level
		auto Player = Game::Cody;
		if (Trace::ComponentOverlapComponent(
			Player.CapsuleComponent,
			PropellerMesh,
			PropellerMesh.WorldLocation,
			PropellerMesh.ComponentQuat,
			bTraceComplex = false
		))
		{
			if (Player.HasControl())
			{
				KillPlayer(Player, DeathEffect);
			}
		}
	}
}