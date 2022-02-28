
UCLASS(Config = Editor)
class UVisualDebugSystem : UHazeVisualDebugMenu
{
	UFUNCTION()
	void ExtractAll(const TArray<FHazeDebugOffsetInstanceData>& InfoArray, FString& OutString)
	{
		OutString += "\n";

		int Counter = 1;
		for(FHazeDebugOffsetInstanceData Instance : InfoArray)
		{
			ExtranceComponentInformation(Counter, Instance, OutString);
			ExtractTranslationDebugInfo(Instance, OutString);
			ExtractRotationDebugInfo(Instance, OutString);
			OutString += "\n";
			Counter++;
		}

		ExtranceBoxColowInformation(OutString);
	}

	UFUNCTION()
	void ExtractTranslationData(const TArray<FHazeDebugOffsetInstanceData>& InfoArray, FString& OutString)
	{
		OutString += "\n";

		int Counter = 1;
		for(FHazeDebugOffsetInstanceData Instance : InfoArray)
		{
			ExtranceComponentInformation(Counter, Instance, OutString);
			ExtractTranslationDebugInfo(Instance, OutString);
			OutString += "\n";
			Counter++;
		}
		
		ExtranceBoxColowInformation(OutString);
	}

	UFUNCTION()
	void ExtractRotationData(const TArray<FHazeDebugOffsetInstanceData>& InfoArray, FString& OutString)
	{
		OutString += "\n";

		int Counter = 1;
		for(FHazeDebugOffsetInstanceData Instance : InfoArray)
		{
			ExtranceComponentInformation(Counter, Instance, OutString);
			ExtractRotationDebugInfo(Instance, OutString);
			OutString += "\n";
			Counter++;
		}

		ExtranceBoxColowInformation(OutString);
	}

	void ExtranceComponentInformation(const int Counter, const FHazeDebugOffsetInstanceData& Instance, FString& OutString)
	{
		OutString += "" + Counter + ". ";
		OutString += " <Grey>" + Instance.ComponentName + "</> (";
		OutString += "Attached on: <Grey>" + Instance.ParentName + "</>)\n";
	}

	void ExtractTranslationDebugInfo(const FHazeDebugOffsetInstanceData& Instance, FString& OutString)
	{
		OutString += "<Grey>Translation</>: ";
		if(ExtractPartInfo(Instance.TranslationInformation, OutString))
		{
			OutString += "	From: " + Instance.StartLocation.ToColorString() + " To: " + Instance.TargetLocation.ToColorString() + "\n";
			OutString += "	Disance Left: " + TrimFloatValue(Instance.CurrentLocation.Distance(Instance.TargetLocation)) + "\n";
			OutString += "	Local Offset: " + Instance.LocalLocation.ToColorString() + "\n";		
		}
	}

	void ExtractRotationDebugInfo(const FHazeDebugOffsetInstanceData& Instance, FString& OutString)
	{
		OutString += "<Grey>Rotation</>: ";
		if(ExtractPartInfo(Instance.RotationInformation, OutString))
		{
			OutString += "	From: " + Instance.StartRotation.ToColorString() + " To: " + Instance.TargetRotation.ToColorString() + "\n";
			OutString += "	Disance Left: " + TrimFloatValue(Instance.CurrentRotation.Vector().AngularDistance(Instance.TargetRotation.Vector())) + "\n";
			OutString += "	Local Offset: " + Instance.LocalRotation.ToColorString() + "\n";
		}
	}

	bool ExtractPartInfo(const FHazeDebugOffsetInstancePartData& Instance, FString& OutString)
	{
		bool bPrintActiveType = false;
		if(Instance.ActiveType == EHazeOffsetLerpActiveType::WorldOffset)
		{
			OutString += "Active with ";
			OutString += "<Green>Offset</>\n";
			bPrintActiveType = true;
		}
		else if(Instance.ActiveType == EHazeOffsetLerpActiveType::WorldOffsetIdle)
		{
			OutString += "Active with ";
			OutString += "<Blue>Offset Idle</>\n";
			bPrintActiveType = true;
		}
		else if(Instance.ActiveType == EHazeOffsetLerpActiveType::WorldReset)
		{
			OutString += "Active with ";
			OutString += "<Red>Resetting</>\n";
			bPrintActiveType = true;
		}
		else if(Instance.ActiveType == EHazeOffsetLerpActiveType::RelativeOffset)
		{
			OutString += "Active with ";
			OutString += "<Green>Relative Offset</>\n";
			bPrintActiveType = true;
		}
		else if(Instance.ActiveType == EHazeOffsetLerpActiveType::RelativeOffsetIdle)
		{
			OutString += "Active with ";
			OutString += "<Blue>Relative Offset Idle</>\n";
			bPrintActiveType = true;
		}
		else if(Instance.ActiveType == EHazeOffsetLerpActiveType::RelativeReset)
		{
			OutString += "Active with ";
			OutString += "<Red>Resetting Relative</>\n";
			bPrintActiveType = true;
		}		
		else
		{
			OutString += "<Grey>Inactive</>\n";
		}

		if(bPrintActiveType)
		{	
			OutString += "	Lerp Type: ";
			if(Instance.LerpType == EHazeOffsetLerpType::Speed)
			{
				OutString += "<Yellow>Speed</> Current: ";
				OutString += TrimFloatValue(Instance.CurrentLerpValue);
				OutString += " | Speed: ";
				OutString += TrimFloatValue(Instance.SpeedInformation.Speed);
				OutString += "\n";
			}
			else if(Instance.LerpType == EHazeOffsetLerpType::Time)
			{
				OutString += "<Blue>Time</> Current: ";
				OutString += TrimFloatValue(Instance.CurrentLerpValue);
				OutString += " | Time: ";
				OutString += TrimFloatValue(Instance.TimeInformation.Time);
				OutString += " | Delay: ";
				OutString += TrimFloatValue(Instance.TimeInformation.StartDelay);
				OutString += "\n";
			}	
			else if(Instance.LerpType == EHazeOffsetLerpType::Accelerate)
			{
				OutString += "<Orange>Acceleration</> Current: ";
				OutString += TrimFloatValue(Instance.CurrentLerpValue);
				OutString += " | StartSpeed: ";
				OutString += TrimFloatValue(Instance.AccelerationInformation.StartSpeed);
				OutString += " | Acceleration: ";
				OutString += TrimFloatValue(Instance.AccelerationInformation.Acceleration);
				OutString += " | MaxSpeed: ";
				OutString += TrimFloatValue(Instance.AccelerationInformation.MaxSpeed);
				OutString += "\n";
			}
			else
			{
				OutString += "Not Implemented\n";
			}
		}

		return bPrintActiveType;
	}

	UFUNCTION()
	void DrawDebugShape(AHazeActor Owner, const FHazeDebugOffsetInstanceData& Instance)
	{
		FVector DebugExtends = Instance.BoundsBoxExtend;
		FVector DebugOrigin = Instance.BoundsOrigin;
		FRotator DebugRotation = Instance.WorldRotation;

		AHazeCharacter CharacterOwner = Cast<AHazeCharacter>(Owner);
		float Radius = 0.f;
		float HalfHeight = 0.f;
		if(CharacterOwner != nullptr)
		{
			UCapsuleComponent CollisionComp = UCapsuleComponent::Get(Owner);
			CollisionComp.GetScaledCapsuleSize(Radius, HalfHeight);
			DebugExtends.X = Radius * 2.f;
			DebugExtends.Y = Radius;
			DebugExtends.Z = HalfHeight;
		}

		const bool bRotationIsActive = Instance.RotationInformation.ActiveType != EHazeOffsetLerpActiveType::Inactive;
		const bool bLocationIsActive = Instance.TranslationInformation.ActiveType != EHazeOffsetLerpActiveType::Inactive;
		if(bLocationIsActive || bRotationIsActive)
		{
			FVector StartLocation = DebugOrigin;
			FVector TargetLocation = DebugOrigin;
			if(bLocationIsActive)
			{
				StartLocation = Instance.StartLocation;
				TargetLocation = Instance.TargetLocation;
			}

			FRotator StartRotation = DebugRotation;
			FRotator TargetRotation = DebugRotation;
			if(bRotationIsActive)
			{
				StartRotation = Instance.StartRotation;
				TargetRotation = Instance.TargetRotation;
			}

			// Actor
			System::DrawDebugBox(
				Owner.GetActorCenterLocation(),
				DebugExtends,
				FLinearColor::Blue,
				Owner.GetActorRotation()
			);

			// Current
			System::DrawDebugBox(
				Instance.CurrentLocation + (Instance.CurrentRotation.UpVector * HalfHeight),
				DebugExtends,
				FLinearColor::Black,
				Instance.CurrentRotation,
				Thickness = 1.5f
			);
	
			// Target
			System::DrawDebugBox(
				TargetLocation + (Instance.TargetRotation.UpVector * HalfHeight),
				DebugExtends,
				FLinearColor::Red,
				TargetRotation
			);
		}
		else
		{
			System::DrawDebugBox(
				DebugOrigin + (DebugRotation.UpVector * HalfHeight),
				DebugExtends,
				FLinearColor::Gray,
				DebugRotation,
				Thickness = 1.5f
			);
		}
	}

	void ExtranceBoxColowInformation(FString& OutString)
	{
		OutString += "Box Colors\n";
		OutString += "<Blue>Blue</>: Actor Transform\n";
		OutString += "<Grey>Gray</>: Inactive OffsetComponent Transform\n";
		OutString += "<DarkGrey>Black</>: Active OffsetComponent Transform\n";	
		OutString += "<Red>Red</>: Target Transform\n";
		OutString += "\n";
	}
}