UCLASS(Abstract)
class AFollowingEye : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent EyeRoot;

	UPROPERTY(DefaultComponent, Attach = EyeRoot)
	UStaticMeshComponent EyeMesh;

	UPROPERTY(DefaultComponent)
	UHazeDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 5000.f;
	default DisableComp.bRenderWhileDisabled = true;

	UPROPERTY()
	float FollowSpeed = 4.f;

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		FVector DirToPlayer = (Game::GetMay().ActorLocation + FVector(0.f, 0.f, 200.f)) - ActorLocation;
		DirToPlayer.Normalize();

		FRotator CurRot = FMath::RInterpTo(ActorRotation, DirToPlayer.Rotation(), DeltaTime, FollowSpeed);

		SetActorRotation(CurRot);
	}
}