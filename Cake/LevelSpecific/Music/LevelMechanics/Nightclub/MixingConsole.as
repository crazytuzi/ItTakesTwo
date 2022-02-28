import Cake.LevelSpecific.Music.LevelMechanics.Nightclub.MixingConsoleConnectedActor;
import Cake.LevelSpecific.Music.Singing.SongReactionComponent;

UCLASS(Abstract)
class AMixingConsole : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent ConsoleRoot;

	UPROPERTY(DefaultComponent, Attach = ConsoleRoot)
	UStaticMeshComponent ConsoleMesh;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USongReactionComponent SongReaction;

	UPROPERTY(EditDefaultsOnly)
	UStaticMesh SliderMesh;

	UPROPERTY()
	int AmountOfSliders = 5.f;

	UPROPERTY()
	float ConsoleWidth = 10000.f;

	UPROPERTY()
	TArray<AMixingConsoleConnectedActor> ConnectedActors;

	UPROPERTY(NotEditable, NotVisible)
	TArray<USceneComponent> SliderRoots;
	UPROPERTY(NotEditable, NotVisible)
	TArray<UStaticMeshComponent> AllSliders;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		SliderRoots.Empty();
		AllSliders.Empty();

		float DistanceBetweenSliders = ConsoleWidth / (AmountOfSliders - 1);

		for (int Index = 0, Count = AmountOfSliders; Index < Count; ++Index)
		{
			USceneComponent CurSliderRoot = USceneComponent::Create(this);
			UStaticMeshComponent CurSlider = UStaticMeshComponent::Create(this);
			CurSlider.SetStaticMesh(SliderMesh);

			FVector Pos = FVector((ConsoleWidth/2) - (DistanceBetweenSliders * Index), -1150.f, 200.f);

			CurSliderRoot.SetRelativeLocation(Pos);

			CurSlider.AttachToComponent(CurSliderRoot);
			CurSlider.SetRelativeRotation(FRotator(0.f, 0.f, -10.f));
			CurSlider.SetRelativeScale3D(FVector(1.f, 2.f, 1.f));

			SliderRoots.Add(CurSliderRoot);
			AllSliders.Add(CurSlider);
		}
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		int Index = 0;

		for (USceneComponent CurSliderRoot : SliderRoots)
		{
			UStaticMeshComponent CurSlider = AllSliders[Index];
			float DistanceToPlayer = (CurSliderRoot.WorldLocation - Game::GetMay().ActorLocation).Size();
			float TargetOffset;

			if (SongReaction.IsAffectedBySongOfLife() && DistanceToPlayer < 750.f)
			{
				TargetOffset = 500.f;
				if (ConnectedActors.Num() > Index)
					ConnectedActors[Index].UpdateTargetLocation(true);
			}
			else
			{
				TargetOffset = 0.f;
				if (ConnectedActors.Num() > Index)
					ConnectedActors[Index].UpdateTargetLocation(false);
			}

			FVector TargetLoc = CurSliderRoot.WorldLocation + (CurSlider.RightVector * TargetOffset);
			FVector CurLoc = FMath::VInterpTo(CurSlider.WorldLocation, TargetLoc, DeltaTime, 1.f);
			CurSlider.SetWorldLocation(CurLoc);

			Index++;
		}
	}
}