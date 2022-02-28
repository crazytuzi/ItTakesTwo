UCLASS(Abstract)
class ASpaceBowlDoor : AHazeActor
{
	UPROPERTY(RootComponent, DefaultComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent LeftRoot;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent RightRoot;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent OpenDoorsAudioEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent CloseDoorsAudioEvent;

	UPROPERTY()
	FHazeTimeLike MoveDoorsTimelike;
	default MoveDoorsTimelike.Duration = 1.f;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		MoveDoorsTimelike.SetPlayRate(2.f);
		MoveDoorsTimelike.BindUpdate(this, n"UpdateMoveDoors");
	}

	UFUNCTION()
	void ForceOpenDoors()
	{
		LeftRoot.SetRelativeLocation(FVector(500.f, 0.f, 0.f));
		RightRoot.SetRelativeLocation(FVector(-500.f, 0.f, 0.f));
	}

	UFUNCTION()
	void OpenDoors()
	{
		MoveDoorsTimelike.Play();
		UHazeAkComponent::HazePostEventFireForget(OpenDoorsAudioEvent, this.GetActorTransform());
	}

	UFUNCTION()
	void CloseDoors()
	{
		MoveDoorsTimelike.Reverse();
		UHazeAkComponent::HazePostEventFireForget(CloseDoorsAudioEvent, this.GetActorTransform());
	}

	UFUNCTION()
	void UpdateMoveDoors(float CurValue)
	{
		float CurOffset = FMath::Lerp(250.f, 500.f, CurValue);
		LeftRoot.SetRelativeLocation(FVector(CurOffset, 0.f, 0.f));
		RightRoot.SetRelativeLocation(FVector(-CurOffset, 0.f, 0.f));
	}
}