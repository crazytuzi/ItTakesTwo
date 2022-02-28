import Cake.LevelSpecific.Garden.Sickle.Enemy.SickleCuttableComponent;
import Cake.LevelSpecific.Garden.Greenhouse.RootCluster.ShieldedBulb;

event void FOnGiantBulbExploded();
event void FOnGiantBulbOpened();

class AGiantBulb : AHazeActor
{
	UPROPERTY(RootComponent, DefaultComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USkeletalMeshComponent SkeletalMesh;
	
	UPROPERTY(DefaultComponent, Attach = RootComp)
	USphereComponent SphereCollision;

	UPROPERTY(DefaultComponent, Attach = SphereCollision)
	USickleCuttableHealthComponent SickleCuttableComp;
	default SickleCuttableComp.MaxHealth = 30.0f;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UStaticMeshComponent ShellMesh;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UStaticMeshComponent ShellFlapMesh;

	UPROPERTY(DefaultComponent, Attach = ShellFlapMesh)
	UBoxComponent VineCollider;

	UPROPERTY(DefaultComponent, Attach = VineCollider)
	UVineImpactComponent VineImpactComp;

	UPROPERTY(DefaultComponent, Attach = ShellFlapMesh)
	UHazeAkComponent LeafAkComp;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent BulbDamageSickleAudioEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent BulbExplodeAudioEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent BulbOpenAudioEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent LeafVineConnectedAudioEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent LeafVineDisconnectedAudioEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent LeafClosedAudioEvent;

	UPROPERTY()
	FOnGiantBulbExploded OnBulbExploded;
	UPROPERTY()
	FOnGiantBulbOpened OnBulbOpened;

	UPROPERTY(Category="References")
	TArray<AShieldedBulb> ShieldedBulbs;

	UPROPERTY(Category="References")
	AGameplayUnwitherSphereActor UnwitherSphere;

	FTimerHandle OpenTimerHandler;
	FTimerHandle UnWitherTimerHandler;

	float OpenBulbDelay = 0.5f;
	float UnWitherDelay = 16.0f;

	UPROPERTY()
	FHazeTimeLike RotateShellFlapTimeLike;

	float OpenFlapPitch = -70.0f;
	float ClosedFlapPitch = 0.0f;

	UPROPERTY()
	UNiagaraSystem DestroyEffect;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SickleCuttableComp.OnCutWithSickle.AddUFunction(this, n"OnCutWithSickle");
		SickleCuttableComp.ChangeValidActivator(EHazeActivationPointActivatorType::None);

		for(AShieldedBulb Bulb : ShieldedBulbs)
		{
			Bulb.OnBulbExploded.AddUFunction(this, n"ShieldedBulbExploded");
		}

		VineImpactComp.OnVineConnected.AddUFunction(this, n"VineConnected");
		VineImpactComp.OnVineDisconnected.AddUFunction(this, n"VineDisconnected");
		VineImpactComp.ChangeValidActivator(EHazeActivationPointActivatorType::None);

		RotateShellFlapTimeLike.BindUpdate(this, n"UpdateTimeLike");
	}

	UFUNCTION()
	void ShieldedBulbExploded(AShieldedBulb Bulb)
	{
		ShieldedBulbs.Remove(Bulb);

		if(ShieldedBulbs.Num() <= 0)
			OpenTimerHandler = System::SetTimer(this, n"OpenBulb", OpenBulbDelay, false);
	}

	UFUNCTION()
	void OpenBulb()
	{
		UnWitherTimerHandler = System::SetTimer(this, n"StartUnWitherSphere", UnWitherDelay, false);

		//make double interact, open up but cody has to hold with whip for may to be able to cut
		VineImpactComp.ChangeValidActivator(EHazeActivationPointActivatorType::Cody);
		OnBulbOpened.Broadcast();

		UHazeAkComponent::HazePostEventFireForget(BulbOpenAudioEvent, this.GetActorTransform());
	}

	UFUNCTION()
	void StartUnWitherSphere()
	{
		UnwitherSphere.Wither();
	}

	UFUNCTION()
	void VineConnected()
	{
		SickleCuttableComp.ChangeValidActivator(EHazeActivationPointActivatorType::May);
		LeafAkComp.HazePostEvent(LeafVineDisconnectedAudioEvent);
		RotateShellFlapTimeLike.Play();

		LeafAkComp.HazePostEvent(LeafVineConnectedAudioEvent);
	}

	UFUNCTION()
	void VineDisconnected()
	{
		SickleCuttableComp.ChangeValidActivator(EHazeActivationPointActivatorType::None);
		RotateShellFlapTimeLike.Reverse();
	}

	UFUNCTION()
	void UpdateTimeLike(float Duration)
	{
		float NewPitch = FMath::Lerp(ClosedFlapPitch, OpenFlapPitch, RotateShellFlapTimeLike.Value);

		FRotator NewRotation = ShellFlapMesh.RelativeRotation;
		NewRotation.Pitch = NewPitch;

		ShellFlapMesh.SetRelativeRotation(NewRotation);

		LeafAkComp.SetRTPCValue("Rtpc_Garden_Shared_Interactable_InfectedBulb_Leaf_Rotation", FMath::Abs(NewPitch));
		
		if(RotateShellFlapTimeLike.IsReversed() && FMath::Abs(NewPitch) == ClosedFlapPitch)
			LeafAkComp.HazePostEvent(LeafClosedAudioEvent);
	}
	
	UFUNCTION()
	void OnCutWithSickle(int DamageAmount)
	{
		UHazeAkComponent::HazePostEventFireForget(BulbDamageSickleAudioEvent, this.GetActorTransform());
		
		if(SickleCuttableComp.Health <= 0)
		{
			Explode();
		}
	}

	UFUNCTION()
	void Explode()
	{
		UHazeAkComponent::HazePostEventFireForget(BulbExplodeAudioEvent, this.GetActorTransform());
		
		System::ClearAndInvalidateTimerHandle(OpenTimerHandler);
		System::ClearAndInvalidateTimerHandle(UnWitherTimerHandler);
		
		Niagara::SpawnSystemAtLocation(DestroyEffect, GetActorLocation());
		OnBulbExploded.Broadcast();
		DestroyActor();
	}
}
