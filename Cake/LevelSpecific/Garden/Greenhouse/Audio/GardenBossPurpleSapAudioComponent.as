import Cake.Environment.GPUSimulations.PaintablePlane;
import Vino.Audio.AudioActors.HazeAmbientSound;

class FSapAudioLocation
{	
	FVector Location;
	bool bActive = false;
}

class UGardenBossPurpleSapAudioComponent : UActorComponent
{	
	UHazeAkComponent SapPlaneHazeAkComp;
	APaintablePlane PaintablePlane;

	UPROPERTY(Category = "PurpleSap")
	UAkAudioEvent SapPlaneEvent;
	
	UPROPERTY()
	TArray<FVector> SapLocations;
	TArray<FSapAudioLocation> SapAudioLocations;

	TArray<FTransform> ActiveSapAudioLocations;	
	private bool bHasUpdatedSapLocations = false;

	FHazeAudioEventInstance PurpleSapEventInstance;
	float CurrSapAmount = 0.f;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SapPlaneHazeAkComp = UHazeAkComponent::Create(Owner, n"SapPlaneHazeAkComp");

		for(FVector Location : SapLocations)
		{
			FSapAudioLocation SapAudioLocation = FSapAudioLocation();
			SapAudioLocation.Location = Location;

			SapAudioLocations.Add(SapAudioLocation);
		}

		//CurrSapAmount = 0.1;
		//SetSapAmountRtpc(CurrSapAmount);		
	}

	UFUNCTION()
	void AddSapAudioLocation(FSapAudioLocation& SapAudioLocation, bool bAddToSapAudioLocations = false)
	{
		ActiveSapAudioLocations.Add(FTransform(SapAudioLocation.Location));
		bHasUpdatedSapLocations = true;		
		SapAudioLocation.bActive = true;

		if(bAddToSapAudioLocations)
			SapAudioLocations.Add(SapAudioLocation);

		CurrSapAmount += 0.2f;
		SetSapAmountRtpc(CurrSapAmount);
	}

	UFUNCTION()
	void RemoveSapAudioLocation(FSapAudioLocation& SapAudioLocation, bool bRemoveFromSapAudioLocations = false)
	{
		ActiveSapAudioLocations.RemoveSwap(FTransform(SapAudioLocation.Location));
		bHasUpdatedSapLocations = true;	
		SapAudioLocation.bActive = false;	

		if(bRemoveFromSapAudioLocations)
			SapAudioLocations.RemoveSwap(SapAudioLocation);

		CurrSapAmount -= 0.2f;
		SetSapAmountRtpc(CurrSapAmount);
	}

	private void QuerySapAtAudioLocation(FSapAudioLocation& AudioLocation)
	{
		if(IsSapAtLocation(AudioLocation) && !AudioLocation.bActive)
			AddSapAudioLocation(AudioLocation);
		else if(!IsSapAtLocation(AudioLocation) && AudioLocation.bActive)
			RemoveSapAudioLocation(AudioLocation);
	}

	private bool IsSapAtLocation(FSapAudioLocation& AudioLocation)
	{		
		if(PaintablePlane.QueryData(AudioLocation.Location).Color.R >= 0.375f)
			return true;

		return false;
	}

	private void SetSapAmountRtpc(float Value)
	{
		SapPlaneHazeAkComp.SetRTPCValue("Rtpc_Garden_Greenhouse_Boss_PurpleSap_LargeBody_Amount", Value);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(PaintablePlane != nullptr)
		{
			for(FSapAudioLocation AudioLocation : SapAudioLocations)
			{
				QuerySapAtAudioLocation(AudioLocation);
				//System::DrawDebugSphere(AudioLocation.Location, 50.f);
			}

			if(bHasUpdatedSapLocations)
			{				
				SapPlaneHazeAkComp.HazeSetMultiplePositions(ActiveSapAudioLocations);
				bHasUpdatedSapLocations = false;
			}

			// We have started setting sap positions but not yet started audio, do that now
			if(!SapPlaneHazeAkComp.EventInstanceIsPlaying(PurpleSapEventInstance) && ActiveSapAudioLocations.Num() > 0)
				PurpleSapEventInstance = SapPlaneHazeAkComp.HazePostEvent(SapPlaneEvent);
		}
		
		// If the purple sap plane is inactive but we are still playing audio, stop it now
		else if (SapPlaneHazeAkComp.HazeIsEventActive(PurpleSapEventInstance.EventID))
			SapPlaneHazeAkComp.HazeStopEvent(PurpleSapEventInstance.PlayingID);		
	}
}