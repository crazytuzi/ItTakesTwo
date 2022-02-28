import Cake.LevelSpecific.Music.Singing.PowerfulSong.PowerfulSongImpactComponent;
import Cake.LevelSpecific.Music.LevelMechanics.Backstage.CablePulse.SpeakerLauchVolume;

class AClassicFlute : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;
	UPROPERTY(DefaultComponent, Attach = RootComp)
	UStaticMeshComponent MeshBody;
	UPROPERTY(DefaultComponent, Attach = RootComp)
	UNiagaraComponent WindParticleSystem;
	UPROPERTY(DefaultComponent, Attach = RootComp)
	UNiagaraComponent LoopingWindParticleSystem;
	UPROPERTY(DefaultComponent, Attach = RootComp)
	UBoxComponent BoxComponent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent MegaFluteBlastEvent;

	UPROPERTY()
	ASpeakerLaunchVolume LaunchVolume;

	AActor OverlappingPlayer;

	UPROPERTY()
	float ImpulsValue = 3000.f;


	UPROPERTY()
	FHazeAcceleratedFloat AcceleratedFloatGlow;
	UPROPERTY()
	FHazeAcceleratedFloat AcceleratedFloatGlowSize;
	UPROPERTY()
	FHazeAcceleratedFloat AcceleratedFloatGlowStrength;


	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		MeshBody.SetScalarParameterValueOnMaterials(n"Glow", 0);
		MeshBody.SetScalarParameterValueOnMaterials(n"GlowSize", 1);
		MeshBody.SetScalarParameterValueOnMaterials(n"GlowStrength", 5);
	}

	bool bPowerfulSongActive;

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		//PrintToScreen("bPowerfulSongActive " + bPowerfulSongActive);
		MeshBody.SetScalarParameterValueOnMaterials(n"Glow", AcceleratedFloatGlow.Value);
		MeshBody.SetScalarParameterValueOnMaterials(n"GlowSize", AcceleratedFloatGlowSize.Value);
		MeshBody.SetScalarParameterValueOnMaterials(n"GlowStrength", AcceleratedFloatGlowStrength.Value);

		if(bPowerfulSongActive)
		{
			AcceleratedFloatGlow.SpringTo(1.3, 120, 1.0, DeltaSeconds);
			AcceleratedFloatGlowSize.SpringTo(0.2f, 25, 1.0, DeltaSeconds);
			AcceleratedFloatGlowStrength.SpringTo(2.f, 20, 1.0, DeltaSeconds);
			return;
		}
	}


	UFUNCTION()
		void ImpulsPlayer()
	{
		System::SetTimer(this, n"ImpulsPlayerFire", 0.2f, false);
		System::SetTimer(this, n"DisableWind", 0.75f, false);
		System::SetTimer(this, n"SetPowerfulShoutBool", 0.65f, false);
		AcceleratedFloatGlow.Value = 0;
		bPowerfulSongActive = true;
		WindParticleSystem.Activate();
		UHazeAkComponent::HazePostEventFireForget(MegaFluteBlastEvent, FTransform());
	}

	UFUNCTION()
	void ImpulsPlayerFire()
	{
		LaunchVolume.LaunchPlayers();

		/*
		TArray<AActor> InsideActors;
		BoxComponent.GetOverlappingActors(InsideActors);


		for (auto Actor : InsideActors)
		{
			if (Cast<AHazePlayerCharacter>(Actor) != nullptr)
			{
				OverlappingPlayer = Actor;
				UHazeMovementComponent MoveComp = UHazeMovementComponent::Get(OverlappingPlayer);
				MoveComp.Velocity = 0;
				Cast<AHazePlayerCharacter>(OverlappingPlayer).AddImpulse(BoxComponent.GetUpVector() * ImpulsValue);
			}
		}
		*/
	}

	UFUNCTION()
	void DisableWind()
	{
		WindParticleSystem.Deactivate();
	}
	UFUNCTION()
	void SetPowerfulShoutBool()
	{
		bPowerfulSongActive = false;
		AcceleratedFloatGlow.Value = 0;
	}
}

