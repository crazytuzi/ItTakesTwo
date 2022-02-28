import Cake.LevelSpecific.Music.MusicalChairs.MusicalChairsActor;
import Cake.LevelSpecific.Music.MusicalChairs.MusicalChairsPlayerComponent;

class UMusicalChairsRadioDancingCapability : UHazeCapability
{
	default CapabilityTags.Add(n"MusicalChairs");

	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 100;

	AMusicalChairsActor MusicalChairs;

	FVector StartLocation;
	FVector EndLocation;
	FVector ResetLocation;
	FVector ResetScale;
	FVector DanceLocation1;
	FVector DanceLocation2;

	FVector StartScale;
	FVector DanceScale;

	bool bResettingToStart = false;
	bool bFlyingUp = false;

	float HowHighToFlyUp = 150.0f;
	float HowFarToDance = 50.0f;
	float HowMuchToScale = 0.05f;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		MusicalChairs = Cast<AMusicalChairsActor>(Owner);
		MusicalChairs.ResetTimeLike.BindUpdate(this, n"UpdateResetTimelike");
		MusicalChairs.ResetTimeLike.BindFinished(this, n"ResetTimelikeFinished");

		MusicalChairs.FlyUpTimeLike.BindUpdate(this, n"UpdateFlyUpTimeLike");
		MusicalChairs.FlyUpTimeLike.BindFinished(this, n"FlyUpTimelikeFinished");

		MusicalChairs.DanceTimeLike.BindUpdate(this, n"UpdateDanceTimeLike");	

		MusicalChairs.DanceSmallVibesTimeLike.BindUpdate(this, n"UpdateDanceSmallVibesTimeLike");	
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(MusicalChairs.bSongIsStopped)
			return EHazeNetworkActivation::DontActivate;
		else
			return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(MusicalChairs.bSongIsStopped)
			return EHazeNetworkDeactivation::DeactivateLocal;
		else
			return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		//start levitating	
		StartLocation = MusicalChairs.SpeakerRoot.RelativeLocation;
		EndLocation = StartLocation;
		EndLocation.Z += HowHighToFlyUp;

		DanceLocation1 = EndLocation;
		DanceLocation1.Z += HowFarToDance;

		DanceLocation2 = EndLocation;
		DanceLocation2.Z -= HowFarToDance;


		StartScale = MusicalChairs.SpeakerRoot.RelativeScale3D;

		DanceScale = StartScale + FVector(0.0f, 0.0f, HowMuchToScale);

		bFlyingUp = true;
		MusicalChairs.FlyUpTimeLike.PlayFromStart();
	}


	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		//FLOPMP back to ground

		MusicalChairs.FlyUpTimeLike.Stop();
		MusicalChairs.DanceTimeLike.Stop();
		MusicalChairs.DanceSmallVibesTimeLike.Stop();

		ResetLocation = MusicalChairs.SpeakerRoot.RelativeLocation;
		ResetScale = MusicalChairs.SpeakerRoot.RelativeScale3D;

		bResettingToStart = true;
		MusicalChairs.ResetTimeLike.PlayFromStart();

		if(MusicalChairs.MusicalChairsSeatHitFloor != nullptr)
			MusicalChairs.AkComponent.HazePostEvent(MusicalChairs.MusicalChairsSeatHitFloor);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{

	}

	UFUNCTION()
	void ResetTimelikeFinished()
	{
		bResettingToStart = false;
	}

	
	UFUNCTION()
	void FlyUpTimelikeFinished()
	{
		bFlyingUp = false;

		if(!MusicalChairs.bSongIsStopped)
		{
			MusicalChairs.DanceTimeLike.PlayFromStart();
			MusicalChairs.DanceSmallVibesTimeLike.PlayFromStart();
		}
	}


	UFUNCTION()
	void UpdateResetTimelike(float CurValue)
	{
		FVector CurrentLocation = FMath::Lerp(ResetLocation, StartLocation, CurValue);
		FVector CurrentScale = FMath::Lerp(ResetScale, StartScale, CurValue);

		MusicalChairs.SpeakerRoot.SetRelativeLocation(CurrentLocation);
		MusicalChairs.SpeakerRoot.SetRelativeScale3D(CurrentScale);
	}

	UFUNCTION()
	void UpdateFlyUpTimeLike(float CurValue)
	{
		FVector CurrentLocation = FMath::Lerp(StartLocation, EndLocation , CurValue);
		MusicalChairs.SpeakerRoot.SetRelativeLocation(CurrentLocation);
	}

	UFUNCTION()
	void UpdateDanceTimeLike(float CurValue)
	{
		FVector CurrentLocation = FMath::Lerp(DanceLocation1, DanceLocation2, CurValue);
		MusicalChairs.SpeakerRoot.SetRelativeLocation(CurrentLocation);
	}

	UFUNCTION()
	void UpdateDanceSmallVibesTimeLike(float CurValue) 
	{
		FVector CurrentScale = FMath::Lerp(StartScale, DanceScale, CurValue);
		MusicalChairs.SpeakerRoot.SetRelativeScale3D(CurrentScale);
	}
}