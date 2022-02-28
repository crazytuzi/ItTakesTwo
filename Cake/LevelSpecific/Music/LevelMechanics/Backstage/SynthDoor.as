
import Cake.LevelSpecific.Music.LevelMechanics.Backstage.SynthDoorStatics;

event void FSynthDoorSignature(bool bSolved);

class ASynthDoor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent LeftMeshRoot;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent RightMeshRoot;

	UPROPERTY(DefaultComponent, Attach = LeftMeshRoot)
	UStaticMeshComponent LeftDoorMesh;

	UPROPERTY(DefaultComponent, Attach = RightMeshRoot)
	UStaticMeshComponent RightDoorMesh;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent DoorOpenAudioEvent;

	UPROPERTY()
	FHazeTimeLike OpenDoorTimeline;

	UPROPERTY()
	FSynthDoorSignature SynthPuzzleSolved;

	bool bSolved = false;

	ESynthDoorComponentIntensity DrumIntensity;
	ESynthDoorComponentIntensity SynthIntensity;
	ESynthDoorComponentIntensity BassIntensity;

	FRotator StartingRot = FRotator::ZeroRotator;
	FRotator TargetRot = FRotator(0.f, 90.f, 0.f);

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		OpenDoorTimeline.BindUpdate(this, n"OpenDoorTimelineUpdate");
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{

	}

	UFUNCTION()
	void OpenDoor()
	{
		OpenDoorTimeline.PlayFromStart();
		UHazeAkComponent::HazePostEventFireForget(DoorOpenAudioEvent, this.GetActorTransform());
	}

	void IntensityChanged(ESynthDoorComponentIntensity Intensity, ESynthDoorMeterType TypeToSet)
	{
		switch (TypeToSet)
		{
			case ESynthDoorMeterType::Synth:
				SynthIntensity = Intensity;
				break;

			case ESynthDoorMeterType::Drum:
				DrumIntensity = Intensity;
				break;

			case ESynthDoorMeterType::Bass:
				BassIntensity = Intensity;
				break;			
		}

		CheckIfPuzzleIsSolved();
	}

	void CheckIfPuzzleIsSolved()
	{
		if (SynthIntensity == ESynthDoorComponentIntensity::High &&
			DrumIntensity == ESynthDoorComponentIntensity::High &&
			BassIntensity == ESynthDoorComponentIntensity::High)
			{
				if (!bSolved)
				{
					bSolved = true;
					SynthPuzzleSolved.Broadcast(bSolved);
				} 
			} else
			{
				if (bSolved)
				{
					bSolved = false;
					SynthPuzzleSolved.Broadcast(bSolved);
				}
			}
	}

	UFUNCTION()
	void OpenDoorTimelineUpdate(float CurrentValue)
	{
		LeftMeshRoot.SetRelativeRotation(FMath::LerpShortestPath(StartingRot, TargetRot * -1, CurrentValue));
		RightMeshRoot.SetRelativeRotation(FMath::LerpShortestPath(StartingRot, TargetRot, CurrentValue));
	}

}