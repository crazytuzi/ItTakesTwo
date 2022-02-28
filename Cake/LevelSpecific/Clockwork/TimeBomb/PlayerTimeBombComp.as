import Cake.LevelSpecific.Clockwork.TimeBomb.WidgetBombTimer;
import Vino.PlayerHealth.PlayerDeathEffect;
import Vino.PlayerHealth.PlayerHealthStatics;
import Cake.LevelSpecific.Clockwork.TimeBomb.BombMesh;

enum ETimeBombState
{
	Default,
	Ready,
	Spawned,
	Ticking,
	Explosion,
	Losing 
};

enum EBombTickState
{
	TickingDown,
	Regenerating
};

enum ETimeBombWinLoseState
{
	Won,
	Lose,
	Draw
}

event void FTimeBombPlayerLose(); 

class UPlayerTimeBombComp : UActorComponent
{
	ETimeBombState TimeBombState;

	FTimeBombPlayerLose EventPlayerLose;

	UPROPERTY(Category = "Setup")
	TSubclassOf<UHazeUserWidget> BombWidget;

	UPROPERTY(Category = "Setup")
	TSubclassOf<UPlayerDeathEffect> DeathEffect;

	UPROPERTY(Category = "Setup")
	UNiagaraSystem BombSpawnEffect;

	UPROPERTY(Category = "Setup")
	TSubclassOf<ABombMesh> BombMeshClass;

	UPROPERTY(Category = "Audio")
	UAkAudioEvent BombBeep1;
	
	UPROPERTY(Category = "Audio")
	UAkAudioEvent BombBeep2;

	UPROPERTY(Category = "Audio")
	UAkAudioEvent BombBeep3;

	UPROPERTY(Category = "Setup")
	UAkAudioEvent BombExplosion;

	UPROPERTY(Category = "Animations")
	TPerPlayer<UAnimSequence> PanicAnims;

	UAnimSequence AnimTest;

	// float CurrentSeconds;
	// float MaxSeconds = 10.f;
	UPROPERTY(Category = "Camera")
	UHazeCameraSpringArmSettingsDataAsset SpringArmSettingsBombRace;

	UPROPERTY(Category = "Setup")
	TSubclassOf<UCameraShakeBase> ExplosionCameraShake;

	ABombMesh BombMesh;

	UHazeAkComponent AkComp;

	UWidgetBombTimer Widget;

	FLinearColor TimeColor;

	UObject TimeBombManager;

	FVector FacingDirection;

	int CountDownStage;

	int MaxCountDownStage = 4;
	// bool bIsRegenerating;

	float CurrentStageSeconds;

	//Initial value should be 2.75.f;
	float MaxStageSeconds = 2.75f;

	float LightRate;

	float MaxLightRate = 0.83f;

	ETimeBombWinLoseState TimeBombWinLoseState;

	bool bResetCamOnRespawn;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		AkComp = UHazeAkComponent::Get(Owner);

		TimeColor.R = 1.f;
		TimeColor.G = 1.f;
		TimeColor.B = 0.f;
		TimeColor.A = 1.f;
	}

	UFUNCTION()
	void CountDownSetter(int Stage)
	{
		switch(Stage)
		{
			case 3:
				LightRate = 0.65f;
			break;
			
			case 2:
				LightRate = 0.4f;
			break;

			case 1:
				LightRate = 0.2f;
			break;

			case 0:
				LightRate = 0.1f;
			break;
		}
	}

	UFUNCTION()
	void PlayCameraShake()
	{
		Game::May.PlayCameraShake(ExplosionCameraShake);
		Game::Cody.PlayCameraShake(ExplosionCameraShake);
	}

	void AudioBeepTime(int Stage)
	{
		switch(Stage)
		{
			case 1: AkComp.HazePostEvent(BombBeep1); break;
			case 2: AkComp.HazePostEvent(BombBeep1); break;
			case 3: AkComp.HazePostEvent(BombBeep2); break;
			case 4: AkComp.HazePostEvent(BombBeep3); break;
		}
	}

	void AudioBombExplosion()
	{
		AkComp.HazePostEvent(BombExplosion);
	}
}