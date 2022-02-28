import Peanuts.Foghorn.FoghornDebugStatics;
import Peanuts.Foghorn.FoghornVoiceLineHelpers;

struct FFoghornActorEffort
{
	AActor Actor;
	UFoghornBarkDataAsset BarkAsset;

	int EventID = 0;
	int PlayingID = 0;
	UHazeAkComponent HazeAkComponent = nullptr;

	float PreDelayTimer = 0.0f;
	int VoiceLineIndex = 0;

	bool BlockOnFinish;
}

class FoghornEfforManager
{
	private TArray<FFoghornActorEffort> Efforts;
	private TArray<AActor> BlockedActors;

	#if !RELEASE
		private TArray<FString> DebugRejectedEvents;
	#endif

	private int FindEffort(AActor Actor)
	{
		for (int i=0; i<Efforts.Num(); ++i)
		{
			if (Efforts[i].Actor == Actor)
			{
				return i;
			}
		}
		return -1;
	}

	private void ResetEffortPlayState(FFoghornActorEffort& Effort)
	{
		Effort.PlayingID = 0;
		Effort.EventID = 0;
		Effort.PreDelayTimer = 0.0f;
		Effort.VoiceLineIndex = -1;
		Effort.BlockOnFinish = false;
	}

	private void StopEffort(FFoghornActorEffort& Effort)
	{
		#if !RELEASE
			FoghornDebugLog("Stopped Effort Event " + Effort.PlayingID);
		#endif

		if (Effort.PlayingID != 0 && IsActorValid(Effort.Actor))
		{
			Effort.HazeAkComponent.HazeStopEvent(Effort.PlayingID, Effort.BarkAsset.Fadeout);
			StopFaceAnimation(Effort);
		}

		ResetEffortPlayState(Effort);
	}

	private bool IsPlaying(FFoghornActorEffort Effort)
	{
		return Effort.PlayingID != 0 || Effort.PreDelayTimer > 0.0f;
	}

	void Reset()
	{
		Stop();
		Efforts.Reset();
		BlockedActors.Reset();
	}

	void Tick(float DeltaTime)
	{
		for (int i = BlockedActors.Num()-1; i>=0; --i)
		{
			if (!IsActorValid(BlockedActors[i]))
			{
				BlockedActors.RemoveAtSwap(i);
				#if !RELEASE
					FoghornDebugLog("Removed destroyed actor from BlockedActors");
				#endif
			}
		}

		for (int i = Efforts.Num()-1; i>=0; --i)
		{
			if (!IsActorValid(Efforts[i].Actor))
			{
				Efforts.RemoveAtSwap(i);
				#if !RELEASE
					FoghornDebugLog("Removed destroyed actor from Efforts");
				#endif
			}
		}

		for (FFoghornActorEffort& Effort : Efforts)
		{
			if (Effort.PreDelayTimer > 0.0f)
			{
				Effort.PreDelayTimer -= DeltaTime;
				if (Effort.PreDelayTimer <= 0.0f)
				{
					PostEvents(Effort);
				}
			}
			else if (Effort.PlayingID != 0)
			{
				if (!IsActorValid(Effort.Actor))
				{
					#if !RELEASE
						FoghornDebugLog("Foghorn Effort actor destroyed, stopping effort");
					#endif
					ResetEffortPlayState(Effort);
					break;
				}

				if (!Effort.HazeAkComponent.HazeIsEventActive(Effort.EventID))
				{
					#if !RELEASE
						FoghornDebugLog("Effort Ended " + Effort.PlayingID);
					#endif

					StopFaceAnimation(Effort);

					if (Effort.BlockOnFinish)
					{
						AActor Actor = Effort.Actor;
						ResetEffortPlayState(Effort);
						BlockActor(Effort.Actor);
					}
					else
					{
						ResetEffortPlayState(Effort);
					}
				}
			}
		}
	}

	void BlockActor(AActor Actor)
	{
		if (!IsActorValid(Actor))
			return;

		int EffortIndex = FindEffort(Actor);
		if (EffortIndex >= 0)
		{
			StopEffort(Efforts[EffortIndex]);
		}

		BlockedActors.AddUnique(Actor);

		#if !RELEASE
			FoghornDebugLog("Effort Blocked Actor Set " + Actor.Name);
		#endif
	}

	void ClearBlockedActor(AActor Actor)
	{
		if (!IsActorValid(Actor))
			return;

		if (BlockedActors.Contains(Actor))
		{
			BlockedActors.RemoveSwap(Actor);

			#if !RELEASE
				FoghornDebugLog("Effort Blocked Actor Cleared " + Actor.Name);
			#endif
		}
	}

	void ClearAllBlockedActors()
	{
		BlockedActors.Empty();

		#if !RELEASE
			FoghornDebugLog("Effort Blocked All Actors Cleared");
		#endif
	}

	void Stop()
	{
		for (FFoghornActorEffort& Effort : Efforts)
		{
			if (IsPlaying(Effort))
			{
				StopEffort(Effort);
			}
		}
		ClearAllBlockedActors();
	}

	void PlayEffort(UFoghornBarkDataAsset BarkAsset, AActor ActorOverride, FFoghornBarkRuntimeData& RuntimeData, bool BlockOnFinish = false)
	{
		#if !RELEASE
			FoghornDebugLog("PlayEffort");
		#endif

		AActor Actor = FoghornVoiceLineHelpers::GetActorForBark(BarkAsset.Character, ActorOverride);
		if (!IsActorValid(Actor))
		{
			#if !RELEASE
				FoghornDebugLog("Invalid actor when playing effort");
			#endif
			return;
		}

		if (BlockedActors.Contains(Actor))
		{
			#if !RELEASE
				FoghornDebugLog("Effort " + BarkAsset.Name + " not started on blocked actor " + Actor.Name);
				DebugRejectedEvents.Add("Effort  " + BarkAsset.Priority + "  " + BarkAsset.Name + "  on  " + Actor.Name + "  Actor Blocked");
			#endif
			return;
		}

		int EffortIndex = FindEffort(Actor);
		if (EffortIndex < 0)
		{
			#if !RELEASE
				FoghornDebugLog("New Effort");
			#endif

			FFoghornActorEffort NewEffort;
			NewEffort.Actor = Actor;
			NewEffort.BarkAsset = BarkAsset;
			Efforts.Add(NewEffort);
			EffortIndex = Efforts.Num()-1;

			StartEffort(Efforts[EffortIndex], RuntimeData, BarkAsset, BlockOnFinish);
			return;
		}

		FFoghornActorEffort& Effort = Efforts[EffortIndex];
		if (!IsPlaying(Effort) || BarkAsset.Priority >= Effort.BarkAsset.Priority)
		{
			Effort.Actor = Actor;
			Effort.BarkAsset = BarkAsset;
			StartEffort(Effort, RuntimeData, BarkAsset, BlockOnFinish);
		}
		#if !RELEASE
		else
		{
			FoghornDebugLog("Effort " + BarkAsset.Name + " not staring with priority " + BarkAsset.Priority + " vs current priority " + Effort.BarkAsset.Priority);
			DebugRejectedEvents.Add("Effort  " + BarkAsset.Priority + "  " + BarkAsset.Name + "  Priority");
		}
		#endif

	}

	void PostEvents(FFoghornActorEffort& Effort)
	{
		if (!IsActorValid(Effort.Actor))
		{
			#if !RELEASE
				FoghornDebugLog("Invalid actor when posting effort events");
			#endif
			ResetEffortPlayState(Effort);
			return;
		}

		FFoghornVoiceLine VoiceLine = Effort.BarkAsset.VoiceLines[Effort.VoiceLineIndex];

		FHazeAudioEventInstance EventInstance = Effort.HazeAkComponent.HazePostEvent(VoiceLine.AudioEvent, "", EHazeAudioPostEventType::Foghorn_Randomized);
		#if !RELEASE
		if (EventInstance.PlayingID == 0)
			FoghornDebugLog("Failed to post effort event on HazeAkComponent " + VoiceLine.AudioEvent.Name);
		#endif
		Effort.EventID = EventInstance.EventID;
		Effort.PlayingID = EventInstance.PlayingID;

		if (VoiceLine.AnimationSequence != nullptr)
		{
			auto HazeActor = Cast<AHazeActor>(Effort.Actor);
			HazeActor.PlayFaceAnimation(FHazeAnimationDelegate(), VoiceLine.AnimationSequence, EHazeExtractCurveMethod::ExtractCurve_Additive, Priority = VoiceLine.AnimPriority);
		}

		#if !RELEASE
			FoghornDebugLog("Effort " + Effort.BarkAsset.Name + " on " + Effort.Actor.Name + " started with ID " + Effort.PlayingID);
		#endif
	}

	void StartEffort(FFoghornActorEffort& Effort, FFoghornBarkRuntimeData& RuntimeData, UFoghornBarkDataAsset BarkAsset, bool BlockOnFinish)
	{
		#if !RELEASE
			FoghornDebugLog("StartEffort");
		#endif
		if (IsPlaying(Effort))
		{
			StopEffort(Effort);
		}

		RuntimeData.PlayedOnce = true;
		RuntimeData.CooldownTimer = BarkAsset.Cooldown;

		Effort.BlockOnFinish = BlockOnFinish;
		Effort.VoiceLineIndex = FoghornVoiceLineHelpers::GetNextVoiceLine(RuntimeData, BarkAsset);

		if (Effort.HazeAkComponent == nullptr)
			Effort.HazeAkComponent = UHazeAkComponent::GetOrCreate(Effort.Actor);


		Effort.PreDelayTimer = Effort.BarkAsset.PreDelay;
		if (Effort.PreDelayTimer <= 0.0f)
		{
			PostEvents(Effort);
			#if !RELEASE
				FoghornDebugLog("No delay");
			#endif
		}
		#if !RELEASE
		else
		{
			FoghornDebugLog("Effort " + Effort.BarkAsset.Name + " on " + Effort.Actor.Name + " started with pre-delay");
		}
		#endif
	}

	private void StopFaceAnimation(FFoghornActorEffort& Effort)
	{
		if (!Effort.BarkAsset.VoiceLines.IsValidIndex(Effort.VoiceLineIndex))
			return;

		const FFoghornVoiceLine& VoiceLine = Effort.BarkAsset.VoiceLines[Effort.VoiceLineIndex];
		if (VoiceLine.AnimationSequence != nullptr)
		{
			auto HazeActor = Cast<AHazeActor>(Effort.Actor);
			HazeActor.StopFaceAnimation(VoiceLine.AnimationSequence);
		}
	}

	#if !RELEASE
	void DebugGetLines(TArray<FString>& OutPlayingEfforts, TArray<FString>& OutRejectedEvents)
	{
		for (FFoghornActorEffort Effort : Efforts)
		{
			if (IsPlaying(Effort))
			{
				FString DbgLine = Effort.Actor.Name + "  " + Effort.BarkAsset.Priority + "  " + Effort.BarkAsset.Name;
				if (Effort.PreDelayTimer > 0.0f)
				{
					DbgLine += "  " + Effort.PreDelayTimer + " pre delay";
				}
				OutPlayingEfforts.Add(DbgLine);
			}
		}
		OutRejectedEvents.Append(DebugRejectedEvents);
		DebugRejectedEvents.Empty();
	}

	void DebugGetEffortLocations(TArray<FFoghornDebugEffortLocation>& OutEffortLocations)
	{
		for (FFoghornActorEffort Effort : Efforts)
		{
			if (IsPlaying(Effort) && Effort.HazeAkComponent != nullptr)
			{
				FFoghornDebugEffortLocation Loc;
				Loc.Location = Effort.HazeAkComponent.WorldLocation;
				Loc.Name = FName("Effort_" + Effort.Actor.Name);
				OutEffortLocations.Add(Loc);
			}
		}
	}
	#endif
}