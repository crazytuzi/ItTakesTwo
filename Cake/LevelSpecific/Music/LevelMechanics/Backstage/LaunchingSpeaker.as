import Cake.LevelSpecific.Music.LevelMechanics.CymbalButton;

class ALaunchingSpeaker : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MeshRoot;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UStaticMeshComponent Mesh;

	UPROPERTY()
	ACymbalButton ConnectedButton;

	UPROPERTY()
	AActor CodyJumpToTarget;

	UPROPERTY()
	AActor MayJumpToTarget;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		ConnectedButton.OnButtonActivated.AddUFunction(this, n"OnButtonActivated");
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{

	}

	UFUNCTION()
	void OnButtonActivated(bool bActivated)
	{
		if (!bActivated)
			return;

		System::SetTimer(this, n"ActivateJump", .5f, false);
	}

	UFUNCTION()
	void ActivateJump()
	{
		FHazeJumpToData CodyJumpData;
		CodyJumpData.Transform = CodyJumpToTarget.GetActorTransform();
		CodyJumpData.AdditionalHeight = 3000.f;

		FHazeJumpToData MayJumpData;
		MayJumpData.Transform = MayJumpToTarget.GetActorTransform();
		MayJumpData.AdditionalHeight = 3000.f;

		JumpTo::ActivateJumpTo(Game::GetCody(), CodyJumpData);
		JumpTo::ActivateJumpTo(Game::GetMay(), MayJumpData);
	}
}