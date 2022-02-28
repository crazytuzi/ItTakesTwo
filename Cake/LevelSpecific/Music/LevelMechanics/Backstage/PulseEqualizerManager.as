import Cake.LevelSpecific.Music.LevelMechanics.Backstage.SynthDoorStatics;
import Cake.LevelSpecific.Music.LevelMechanics.Backstage.DrumMachine.DrumMachine;
import Cake.LevelSpecific.Music.LevelMechanics.Backstage.SynthDoor;
import Cake.LevelSpecific.Music.LevelMechanics.Backstage.EQVuMeter;

class APulseEqualizerManager : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	UBillboardComponent Root;

	UPROPERTY()
	ADrumMachine ConnectedDrumMachine;

	UPROPERTY()
	ADrumMachine ConnectedSynthMachine;

	UPROPERTY()
	ADrumMachine ConnectedBassMachine;

	UPROPERTY()
	ASynthDoor SynthDoor01;

	UPROPERTY()
	ASynthDoor SynthDoor02;

	UPROPERTY()
	TArray<EqVuMeter> SynthVuMeterArray;

	UPROPERTY()
	TArray<EqVuMeter> DrumsVuMeterArray;

	UPROPERTY()
	TArray<EqVuMeter> BassVuMeterArray;

	bool bPulseEqualizerShouldBeActive = false;

	TArray<float> CurrentPulseValueArray;
	TArray<float> BasePulseValueArray;

	TArray<UStaticMeshComponent> MeshCompArray;
	TArray<FLinearColor> HeightArray;

	ESynthDoorComponentIntensity DrumIntensity;
	ESynthDoorComponentIntensity SynthIntensity;
	ESynthDoorComponentIntensity BassIntensity;

	int KickAmount = 0;
	int SnareAmount = 0;
	int CrashAmount = 0;

	int DrumButtonPressGoal = 6;
	int SynthButtonPressGoal = 10;
	int BassButtonPressGoal = 5;

	float InterpSpeed = 2.f;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		for (int i = 0; i < 24; i++)
		{
			CurrentPulseValueArray.Add(0.05f);
			BasePulseValueArray.Add(0.05f);
		}

		for (int i = 0; i < 6; i++)
		{
			HeightArray.Add(FLinearColor::Black);
		}

		TArray<AActor> ActorArray;
		Gameplay::GetAllActorsWithTag(n"Equalizer", ActorArray);

		for (AActor Actor : ActorArray)
		{
			AStaticMeshActor MeshActor = Cast<AStaticMeshActor>(Actor);
			
			if (MeshActor != nullptr)
				MeshCompArray.Add(MeshActor.StaticMeshComponent);
			
		}

		MeshCompArray.Add(SynthDoor01.LeftDoorMesh);
		MeshCompArray.Add(SynthDoor01.RightDoorMesh);
		MeshCompArray.Add(SynthDoor02.LeftDoorMesh);
		MeshCompArray.Add(SynthDoor02.RightDoorMesh);

		ConnectedDrumMachine.OnBeat.AddUFunction(this, n"OnDrumMachine");
		ConnectedSynthMachine.OnBeat.AddUFunction(this, n"OnSynthMachine");
		ConnectedBassMachine.OnBeat.AddUFunction(this, n"OnBassMachineBeat");

		ConnectedDrumMachine.OnButtonToggled.AddUFunction(this, n"OnDrumMachineButtonToggled");
		ConnectedSynthMachine.OnButtonToggled.AddUFunction(this, n"OnSynthMachineButtonToggled");
		ConnectedBassMachine.OnButtonToggled.AddUFunction(this, n"OnBassMachineButtonToggled");

		SetAllEqualizerParamsToZero();
	}

	UFUNCTION()
	void SetPulseEqualizerActive(bool bActive)
	{
		bPulseEqualizerShouldBeActive = bActive;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{	
		for (int i = 0; i < 24; i++)
		{
			CurrentPulseValueArray[i] = FMath::FInterpTo(CurrentPulseValueArray[i], 0.05f, DeltaTime, InterpSpeed);
		}

		ApplyEqualizerParam();
	}

	UFUNCTION()
	void OnDrumMachine(ADrumMachine Machine, int ColumnIndex, int ColumnPressedButtons)
	{
		if (ColumnPressedButtons > 0)
		{
			SetBaseBarValue(DrumIntensity, ESynthDoorMeterType::Drum);
			PulseBar(ESynthDoorMeterType::Drum);
			
			for (auto Vu : DrumsVuMeterArray)
				Vu.GiveVuMeterPulse(DrumIntensity);
		}
	}

	UFUNCTION()
	void OnSynthMachine(ADrumMachine Machine, int ColumnIndex, int ColumnPressedButtons)
	{
		if (ColumnPressedButtons > 0)
		{
			SetBaseBarValue(SynthIntensity, ESynthDoorMeterType::Synth);
			PulseBar(ESynthDoorMeterType::Synth);

			for (auto Vu : SynthVuMeterArray)
				Vu.GiveVuMeterPulse(SynthIntensity);
		}
	}

	UFUNCTION()
	void OnBassMachineBeat(ADrumMachine Machine, int ColumnIndex, int ColumnPressedButtons)
	{
		if (ColumnPressedButtons > 0)
		{
			SetBaseBarValue(BassIntensity, ESynthDoorMeterType::Bass);
			PulseBar(ESynthDoorMeterType::Bass);

			for (auto Vu : BassVuMeterArray)
				Vu.GiveVuMeterPulse(BassIntensity);
		}
	}

	UFUNCTION()
	void OnDrumMachineButtonToggled(ADrumMachine Machine, int RowIndex, int RowPressedButtons, int TotalPressedButtons)
	{
		DrumIntensity = CalculateDrumIntensity(RowIndex, RowPressedButtons, TotalPressedButtons);
	}

	UFUNCTION()
	void OnSynthMachineButtonToggled(ADrumMachine Machine, int RowIndex, int RowPressedButtons, int TotalPressedButtons)
	{
		SynthIntensity = CalculateSynthIntensity(RowIndex, RowPressedButtons, TotalPressedButtons);
	}

	UFUNCTION()
	void OnBassMachineButtonToggled(ADrumMachine Machine, int RowIndex, int RowPressedButtons, int TotalPressedButtons)
	{
		BassIntensity = CalculateBassIntensity(RowIndex, RowPressedButtons, TotalPressedButtons);
	}

	void SetBaseBarValue(ESynthDoorComponentIntensity Intensity, ESynthDoorMeterType TypeToSet)
	{
		float IntensityToSet = 0.f;
		
		switch (Intensity)
		{
			case ESynthDoorComponentIntensity::Low:
				IntensityToSet = 0.05f;
				break;

			case ESynthDoorComponentIntensity::Medium:
				IntensityToSet = 0.35f;
				break;

			case ESynthDoorComponentIntensity::High:
				IntensityToSet = 0.77f;
				break;
		}
		
		switch (TypeToSet)
		{
			case ESynthDoorMeterType::Synth:
				for (int i = 0; i < 8; i++)
				{
					BasePulseValueArray[i] = IntensityToSet;
				}
				break;

			case ESynthDoorMeterType::Drum:
				for (int i = 8; i < 16; i++)
				{
					BasePulseValueArray[i] = IntensityToSet;
				}
				break;

			case ESynthDoorMeterType::Bass:
				for (int i = 16; i < 24; i++)
				{
					BasePulseValueArray[i] = IntensityToSet;
				}
				break;			
		}

		SynthDoor01.IntensityChanged(Intensity, TypeToSet);
		SynthDoor02.IntensityChanged(Intensity, TypeToSet);
	}

	void PulseBar(ESynthDoorMeterType TypeToPulse)
	{
		switch (TypeToPulse)
		{
			case ESynthDoorMeterType::Synth:
				for (int i = 0; i < 8; i++)
				{
					CurrentPulseValueArray[i] = BasePulseValueArray[i] + FMath::RandRange(0.05f, 0.25f);
				}
				break;

			case ESynthDoorMeterType::Drum:
				for (int i = 8; i < 16; i++)
				{
					CurrentPulseValueArray[i] = BasePulseValueArray[i] + FMath::RandRange(0.05f, 0.25f);
				}
				break;

			case ESynthDoorMeterType::Bass:
				for (int i = 16; i < 24; i++)
				{
					CurrentPulseValueArray[i] = BasePulseValueArray[i] + FMath::RandRange(0.05f, 0.25f);
				}
				break;			
		}
	}

	void ApplyEqualizerParam()
	{
		if (!ensure(HeightArray.Num() * 4 == CurrentPulseValueArray.Num()))
			return;
		
		for (int i = 0; i < HeightArray.Num(); i++)
		{
			HeightArray[i] = FLinearColor(CurrentPulseValueArray[i*4], CurrentPulseValueArray[i*4 + 1], CurrentPulseValueArray[i*4 + 2], CurrentPulseValueArray[i*4 + 3]);
		}
		
		for (int i = 0; i < MeshCompArray.Num(); i++)
		{
			for(int j = 0; j < HeightArray.Num(); j++)
			{
				MeshCompArray[i].SetColorParameterValueOnMaterialIndex(1, FName("Height" + (j+1)), HeightArray[j]);
			}
		}
	}

	void SetAllEqualizerParamsToZero()
	{		
		for (int i = 0; i < HeightArray.Num(); i++)
		{
			HeightArray[i] = FLinearColor(0.f, 0.f, 0.f, 0.f);
		}
		
		for (int i = 0; i < MeshCompArray.Num(); i++)
		{
			for(int j = 0; j < HeightArray.Num(); j++)
			{
				MeshCompArray[i].SetColorParameterValueOnMaterialIndex(1, FName("Height" + (j+1)), HeightArray[j]);
			}
		}
	}

	ESynthDoorComponentIntensity CalculateDrumIntensity(int RowIndex, int RowPressedButtons, int TotalPressedButtons)
	{
		if (TotalPressedButtons >= DrumButtonPressGoal)
			return ESynthDoorComponentIntensity::High;
		else if(TotalPressedButtons >= DrumButtonPressGoal/2)
			return ESynthDoorComponentIntensity::Medium;
		else
			return ESynthDoorComponentIntensity::Low;
	}

	ESynthDoorComponentIntensity CalculateSynthIntensity(int RowIndex, int RowPressedButtons, int TotalPressedButtons)
	{
		if (TotalPressedButtons >= SynthButtonPressGoal)
			return ESynthDoorComponentIntensity::High;
		else if (TotalPressedButtons >= SynthButtonPressGoal/2)
			return ESynthDoorComponentIntensity::Medium;
		else
			return ESynthDoorComponentIntensity::Low;
	}

	ESynthDoorComponentIntensity CalculateBassIntensity(int RowIndex, int RowPressedButtons, int TotalPressedButtons)
	{
		if (TotalPressedButtons >= BassButtonPressGoal)
			return ESynthDoorComponentIntensity::High;
		else if (TotalPressedButtons >= BassButtonPressGoal/2)
			return ESynthDoorComponentIntensity::Medium;
		else
			return ESynthDoorComponentIntensity::Low;
	}
}