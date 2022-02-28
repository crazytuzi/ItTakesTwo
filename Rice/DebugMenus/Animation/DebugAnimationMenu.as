
struct FDebugSortedAnimationFeatureInfo
{
	UPROPERTY()
	TArray<FDebugAnimationFeatureInfo> Infos;
}

struct FDebugSortedAnimationFeatureInfoIndex
{
	UPROPERTY()
	UHazeLocomotionAssetBase MainDataAsset;
	
	UPROPERTY()
	TArray<FHazeDebugAnimFeautureData> Data;
}

struct FDebugAnimationFeatureInfo
{
	UPROPERTY()
	FString Text;

	UPROPERTY()
	FLinearColor Color = FLinearColor::White;

	UPROPERTY()
	bool bIsValid = false;
}

FString GetActorTransitionDataText(FHazeDebugTransitionData ActorTransitionData, bool bWithColors = true, bool bWithLocation = false, bool bWithRotation = false)
{
	FString FinalString = "";
	FinalString += "Made Transitions\n";
	
	if(!ActorTransitionData.bHasAnimationControl)
	{
		if(bWithColors)
			FinalString += "<Grey>Upcomming Transition: </>" + ActorTransitionData.UpcomingRemoteTransition;
		else
			FinalString += "Upcomming Transition: " + ActorTransitionData.UpcomingRemoteTransition;
		FinalString += "\n";
	}

	for(const FDebugTransitionLogData& LogIndex : ActorTransitionData.TransitionsLog)
	{
		if(LogIndex.bNetworked)
		{
			if(LogIndex.bTransitionControl == LogIndex.bCurrentAnimationControl)
			{
				if(bWithColors)
				{
					if(LogIndex.bTransitionControl)
						FinalString += "<Grey>- Control Side</>";
					else
						FinalString += "<Grey>- Remote Side</>";
				}
				else
				{
					if(LogIndex.bTransitionControl)
						FinalString += "- Control Side";
					else
						FinalString += "- Remote Side";
				}
			}
			else
			{
				if(bWithColors)
				{
					if(LogIndex.bTransitionControl)
						FinalString += "<Red>(Old Control) </>";
					else
						FinalString += "<Red>(Old Remote) </>";	
				}
				else
				{
					if(LogIndex.bTransitionControl)
						FinalString += "(Old Control) ";
					else
						FinalString += "(Old Remote) ";	
				}
			}
		}

		FinalString += "    ";

		if(LogIndex.bNetworked)
		{
			FinalString += "(" + LogIndex.TransitionCount + ") ";
		}
			
		FinalString += LogIndex.TransitionName.ToString();
		if(bWithColors)
		{
			FinalString += " | <Grey>Time:</> " + LogIndex.GameTime;
			FinalString += " | <Grey>Feature:</> " + LogIndex.FeatureName;
		}
		else
		{
			FinalString += " | Time: " + LogIndex.GameTime;
			FinalString += " | Feature: " + LogIndex.FeatureName;
		}
		
		if(bWithLocation)
		{
			const FVector Location = LogIndex.OwnerTransform.GetLocation();
			FinalString += "Loc: X: " + TrimFloatValue(Location.X) + " Y: " + TrimFloatValue(Location.Y) + " Z: " + TrimFloatValue(Location.Z);
		}

		if(bWithRotation)
		{
			const FRotator Rotation = LogIndex.OwnerTransform.Rotator();
			FinalString += " | Yaw: " + Rotation.Yaw;
		}

		FinalString += "\n";
	}

	return FinalString;
}

class UDebugAnimationMenu : UHazeAnimationDebugMenu
{

	UPROPERTY(Transient, BlueprintReadOnly)
	FHazeDebugAnimInstanceData ActorAnimInstanceData;


	FHazeDebugTransitionData LastActorTransitionData;

	UFUNCTION(BlueprintPure)
	FString GatherAnimationDefaultInfo(AActor CurrentActor)
	{
		FString FinalString = "";
		if(CurrentActor != nullptr)
		{
			if(GatherAnimInstanceInfo(CurrentActor, ActorAnimInstanceData))
			{
				// Main
				FinalString += "<Grey>Locomotion Asset: </>";
				if(ActorAnimInstanceData.CurrentLocomotionAsset != nullptr)
					FinalString += ActorAnimInstanceData.CurrentLocomotionAsset.GetName();
				else
					FinalString += "None";

				FinalString += "\n";

				// Sub
				FinalString += "<Grey>Current Sub Instance: </>";
				if(ActorAnimInstanceData.CurrentFeatureSubAnimInstance != nullptr)
				{
					FinalString += ActorAnimInstanceData.CurrentFeatureSubAnimInstance.GetName();
					if(ActorAnimInstanceData.CurrentFeatureSubAnimInstance.bWaitingForTransition)
						FinalString += "<Red> (Waiting For Transition) </>";
				}
				else
				{
					FinalString += "None";
				}

				FinalString += "\n";

				FinalString += "<Grey>Last Sub Instance: </>";
				if(ActorAnimInstanceData.LastLocomotionAsset != nullptr)
				{
					FinalString += "(" + ActorAnimInstanceData.LastLocomotionAsset.GetName() +")";
				}
				else
				{
					FinalString += "None";
				}

				FinalString += "\n\n";

				// Request
				if(ActorAnimInstanceData.CurrentAnimUpdateParams.LocomotionTag != NAME_None)
				{
					FinalString += "<Grey>Locomotion Tag: </>" + ActorAnimInstanceData.CurrentAnimUpdateParams.LocomotionTag + "\n";
					FinalString += "<Grey>Sub Tag: </>" + ActorAnimInstanceData.CurrentAnimUpdateParams.SubLocomotionTag + "\n";
					FinalString += "<Grey>Requested Velocity: </>" + ActorAnimInstanceData.CurrentAnimUpdateParams.WantedVelocity + "\n";	
				}

				FinalString += "\n\n";
			}
		}
		else
		{
			ActorAnimInstanceData = FHazeDebugAnimInstanceData();
		}

		return FinalString;
	}

	UFUNCTION(BlueprintPure)
	bool DebugAnimationFeatureDataIsEqual(const FHazeDebugAnimFeautureData& A, const FHazeDebugAnimFeautureData& B)const
		{
		if (A.Asset != B.Asset)
			return false;

		if (A.LinkedBundle != B.LinkedBundle)
			return false;

		if (A.LinkedLocomotionAsset != B.LinkedLocomotionAsset)
			return false;

		if (A.TimePeriod != B.TimePeriod)
			return false;

		if (A.bHasNetworkControlActive != B.bHasNetworkControlActive)
			return false;

		if (A.bHasNetworkRemoteActive != B.bHasNetworkRemoteActive)
			return false;

		return true;
	}

	UFUNCTION(BlueprintPure)
	FDebugSortedAnimationFeatureInfo GetSortedFeatureDebugText(TArray<FHazeDebugAnimFeautureData> FromData)
	{
		TArray<FDebugSortedAnimationFeatureInfoIndex> SortedData;
		SortedData.Add(FDebugSortedAnimationFeatureInfoIndex());

		FDebugSortedAnimationFeatureInfoIndex& Default = SortedData[0];
		
		for(int i = 0; i < FromData.Num(); ++i)
		{
			if(FromData[i].Asset == nullptr)
				continue;

			// Sort all the data
			if(FromData[i].LinkedLocomotionAsset == nullptr)
			{
				Default.Data.Add(FromData[i]);
			}
			else
			{
				UHazeLocomotionAssetBase MainAssetName = FromData[i].LinkedLocomotionAsset;
				int FoundIndex = -1;
				for(int ii = 1; ii < SortedData.Num(); ++ii)
				{
					if(SortedData[ii].MainDataAsset == MainAssetName)
					{
						FoundIndex = ii;
						break;
					}
				}

				if(FoundIndex < 0)
				{
					FDebugSortedAnimationFeatureInfoIndex NewIndex;
					NewIndex.MainDataAsset = MainAssetName;
					FoundIndex = SortedData.Num();
					SortedData.Add(NewIndex);
				}

				FDebugSortedAnimationFeatureInfoIndex& Index =  SortedData[FoundIndex];
				Index.Data.Add(FromData[i]);
			}
		}

		FDebugSortedAnimationFeatureInfo Out;

		int i = 1;
		while(true)
		{
			// Place the empty category last
			if(i == SortedData.Num())
				i = 0;

			FDebugSortedAnimationFeatureInfoIndex& Index = SortedData[i];
				
			if(Index.Data.Num() > 0)
			{
				// Main Category
				{
					FDebugAnimationFeatureInfo NewIndex;
					NewIndex.bIsValid = true;
					NewIndex.Color = FLinearColor::Gray;
					
					if(Index.MainDataAsset != nullptr)
						NewIndex.Text = "\n" + Index.MainDataAsset.GetName();
					else
						NewIndex.Text = "\nUnKnown Asset";

					Out.Infos.Add(NewIndex);
				}


				for(int ii = 0; ii < Index.Data.Num(); ++ii)
				{
					FDebugAnimationFeatureInfo NewIndex;
					GetFeatureDebugText(Index.Data[ii], NewIndex);
					Out.Infos.Add(NewIndex);
				}
			}

			// Place the empty category last
			if(i == 0)
				break;
			else
				i++;
		}

		return Out;
	}


	void GetFeatureDebugText(FHazeDebugAnimFeautureData FromData, FDebugAnimationFeatureInfo& Out)
	{
		if(FromData.Asset != nullptr)
		{
			Out.bIsValid = true;

			Out.Text += "    ";

			if(FromData.TimePeriod == EHazeDebugAnimFeautureTimePeriodType::CurrentAndRequested)
			{
				Out.Color = FLinearColor::Green;
				Out.Text += "Current ";
			}
			else if(FromData.TimePeriod == EHazeDebugAnimFeautureTimePeriodType::Last)
			{
				Out.Color = FLinearColor::Gray;
				Out.Text += "Last ";
			}
			else
			{
				if(FromData.TimePeriod == EHazeDebugAnimFeautureTimePeriodType::Current)
				{
					Out.Color = FLinearColor::Red;
					Out.Text += "Current ";
				}
				else if(FromData.TimePeriod == EHazeDebugAnimFeautureTimePeriodType::RequestedForFuture)
				{
					Out.Color = FLinearColor::Yellow;
					Out.Text += "Requested ";
				}
			}

			// Text
			Out.Text += "Feature: " + FromData.Asset.GetName();

			if(FromData.LinkedBundle != nullptr)
			{
				Out.Text += " | " + FromData.LinkedBundle.GetName();
			}
		}
	}

	bool DataIsCurrentAsset(const FHazeDebugAnimFeautureData& Data) const
	{
		if(Data.TimePeriod == EHazeDebugAnimFeautureTimePeriodType::Current)
			return true;
		else if(Data.TimePeriod == EHazeDebugAnimFeautureTimePeriodType::CurrentAndRequested)
			return true;
		else
			return false;
	}

	UFUNCTION(BlueprintPure)
	FString GetTransitionDebugText(AActor CurrentActor)const
	{

		FHazeDebugTransitionData ActorTransitionData;
		AnimationDebug::GatherTransitionInfo(CurrentActor, ActorTransitionData);
		return GetActorTransitionDataText(ActorTransitionData);
	}


	bool DebugTransitionDataDataIsEqual(const FHazeDebugTransitionData& A, const FHazeDebugTransitionData& B)const
	{


		return true;
	}
}