event void FOnDoorHit();

class ACastleWreckingDoor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UBoxComponent Box;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent LeftDoor;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent RightDoor;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent DoorHitByCraneAudioEvent;

	FHazeAcceleratedFloat AcceleratedYaw;

	UPROPERTY(DefaultComponent, Attach = Root)
	UNiagaraComponent DustEffect1;
	default DustEffect1.Deactivate();
	UPROPERTY(DefaultComponent, Attach = Root)
	UNiagaraComponent DustEffect2;
	default DustEffect2.Deactivate();
	UPROPERTY(DefaultComponent, Attach = Root)
	UNiagaraComponent DustEffect3;
	default DustEffect3.Deactivate();
	UPROPERTY()
	FOnDoorHit OnDoorHit;

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		AcceleratedYaw.SpringTo(0.f, 500.f, 0.06f, DeltaTime);

		LeftDoor.SetRelativeRotation(FRotator(0.f, -AcceleratedYaw.Value, 0.f));
		RightDoor.SetRelativeRotation(FRotator(0.f, AcceleratedYaw.Value, 0.f));
	}

	UFUNCTION(BlueprintEvent)
	void HitByWreckingBall(float Strength)
	{
		AcceleratedYaw.Velocity += 600.f * Strength;

		DustEffect1.Activate();
		DustEffect2.Activate();
		DustEffect3.Activate();

		OnDoorHit.Broadcast();

		UHazeAkComponent::HazePostEventFireForget(DoorHitByCraneAudioEvent, this.GetActorTransform());
	}
}