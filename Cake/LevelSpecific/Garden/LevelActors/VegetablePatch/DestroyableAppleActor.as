import Cake.LevelSpecific.Garden.Vine.VineImpactComponent;
import Cake.LevelSpecific.Garden.Sickle.Enemy.SickleCuttableComponent;
import Vino.Movement.Components.GroundPound.GroundPoundThroughComponent;

class ADestroyableAppleActor : AHazeActor
{
	//Vine impact / Scythe hit / Groundpound > Triggers destroy.
	//ON Destroy > Scale up > Trigger > Down > Disable.


	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComponent)
	UStaticMeshComponent MeshComp;

	UPROPERTY(DefaultComponent, Attach = RootComponent)
	USphereComponent AttackTrigger;

	UPROPERTY(DefaultComponent, Attach = AttackTrigger)
	UVineImpactComponent VineImpactComp;

	UPROPERTY(DefaultComponent, Attach = AttackTrigger)
	USickleCuttableComponent SickleCuttableComp;

	UPROPERTY(DefaultComponent)
	UGroundPoundThroughComponent GroundPoundThroughComp;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent DestroyAppleAudioEvent;

	UPROPERTY(Category = "Audio Events")
	float ExplosionVolumeOffset = -8.f;

	UPROPERTY(Category = "Setup")
	UNiagaraSystem DestroyedEffect;

	UPROPERTY(Category = "Setup")
	FHazeTimeLike ScaleTimeLike;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		VineImpactComp.OnVineConnected.AddUFunction(this, n"TriggerDestroyVine");
		SickleCuttableComp.OnCutWithSickle.AddUFunction(this, n"TriggerDestroySickle");
		GroundPoundThroughComp.OnActorGroundPoundedThrough.AddUFunction(this, n"TriggerDestroyGroundPound");

		ScaleTimeLike.BindUpdate(this, n"OnTimeLikeUpdate");
		ScaleTimeLike.BindFinished(this, n"OnTimeLikeFinished");
	}

	UFUNCTION()
	void TriggerDestroySickle(int Damage)
	{
		MeshComp.SetCollisionEnabled(ECollisionEnabled::NoCollision);
		AttackTrigger.SetCollisionEnabled(ECollisionEnabled::NoCollision);

		TMap<FString, float> Rtpcs;
		Rtpcs.Add("Rtpc_Gameplay_Explosions_Shared_VolumeOffset", ExplosionVolumeOffset);
		UHazeAkComponent::HazePostEventFireForgetWithRtpcs(DestroyAppleAudioEvent, this.GetActorTransform(), Rtpcs);

		ScaleTimeLike.PlayFromStart();
	}

	UFUNCTION()
	void TriggerDestroyVine()
	{
		MeshComp.SetCollisionEnabled(ECollisionEnabled::NoCollision);
		AttackTrigger.SetCollisionEnabled(ECollisionEnabled::NoCollision);

		TMap<FString, float> Rtpcs;
		Rtpcs.Add("Rtpc_Gameplay_Explosions_Shared_VolumeOffset", ExplosionVolumeOffset);
		UHazeAkComponent::HazePostEventFireForgetWithRtpcs(DestroyAppleAudioEvent, this.GetActorTransform(), Rtpcs);

		ScaleTimeLike.PlayFromStart();
	}

	UFUNCTION()
	void TriggerDestroyGroundPound(AHazePlayerCharacter GroundPoundingActor)
	{
		MeshComp.SetCollisionEnabled(ECollisionEnabled::NoCollision);
		AttackTrigger.SetCollisionEnabled(ECollisionEnabled::NoCollision);

		TMap<FString, float> Rtpcs;
		Rtpcs.Add("Rtpc_Gameplay_Explosions_Shared_VolumeOffset", ExplosionVolumeOffset);
		UHazeAkComponent::HazePostEventFireForgetWithRtpcs(DestroyAppleAudioEvent, this.GetActorTransform(), Rtpcs);

		ScaleTimeLike.PlayFromStart();
	}

	bool bHasTriggeredEffect = false;

	UFUNCTION()
	void OnTimeLikeUpdate(float Value)
	{
		float PreviousScale = MeshComp.RelativeScale3D.X;

		float NewScale = FMath::Lerp(1.f, 0.f, Value);
		MeshComp.SetRelativeScale3D(FVector(NewScale, NewScale, NewScale));

		if(!bHasTriggeredEffect && NewScale < PreviousScale)
		{
			if(DestroyedEffect != nullptr)
				Niagara::SpawnSystemAtLocation(DestroyedEffect, ActorLocation);

			bHasTriggeredEffect = true;
		}
	}

	UFUNCTION()
	void OnTimeLikeFinished()
	{
		DisableActor(this);
	}
}