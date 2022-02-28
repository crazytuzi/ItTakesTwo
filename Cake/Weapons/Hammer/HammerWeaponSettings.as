
UCLASS(meta = (ComposeSettingsOnto = "UHammerWeaponSettings"))
class UHammerWeaponSettings : UHazeComposableSettings
{
	UPROPERTY(meta = (ShowOnlyInnerProperties, ComposedStruct))
	FHammerWeaponSmashSettings_Default Default;

	UPROPERTY(meta = (ShowOnlyInnerProperties, ComposedStruct))
	FHammerWeaponSmashSettings_Special Special;

	UPROPERTY(Category = "DEBUG")
	bool bDrawDebug = false;
};


USTRUCT(Meta = (ComposedStruct))
struct FHammerWeaponSmashSettings_Default
{
	UPROPERTY(Category = "Default Attack")
	FHazePlaySlotAnimationParams AnimData;

	/* We'll constrain a sphere trace into a cone trace, based on this angle. Unit: Degrees */
	UPROPERTY(Category = "Default Attack")
	float ConeTraceAngle = 45.f;

	/* the length of the cone/sphere trace. */
	UPROPERTY(Category = "Default Attack")
	float ConeTraceLength = 150.f;
};

USTRUCT(Meta = (ComposedStruct))
struct FHammerWeaponSmashSettings_Special
{
	// How many hammerable actors that need to be within range to trigger the special attack
	UPROPERTY(Category = "Special Attack")
	int NumHammerablesThatTriggerSpecial = 2;

	/* Will trigger for all classes (with hammerableComp) if 
		the array is left empty - even players */
    UPROPERTY(Category = "Special Attack")
    TArray<TSubclassOf<AHazeActor>> TriggerOnHammerableActorClasses;

	/* Actor with HammerableComp and TAG within the radius will be affected. */
	UPROPERTY(Category = "Special Attack")
	float SphereTraceRadius = 400.f;

	UPROPERTY(Category = "Special Attack")
	FHazePlayRndSequenceData AnimData;

	UPROPERTY(Category = "Special Attack")
	float BlendTime = 0.2f;
};

//struct FHammerWeaponSmashSettings_Special_AnimationData
//{
//	UPROPERTY()
//	TArray<FHazeAnimSeqAndProbability> Sequences;
//
//	UPROPERTY()
//	float BlendTime = 0.2f;
//
//	UPROPERTY()
//	float PlayRate = 1.0f;
//
//	UPROPERTY()
//	bool bLoop = false;
//
//	UAnimSequence GetSequenceWithException(const UAnimSequence Exception = nullptr) const
//	{
//		if (Exception == nullptr)
//			return GetSequence();
//
//		if (Sequences.Num() == 1)
//		{
//			return Sequences[0].Sequence;
//		}
//		else
//		{
//			int32 ProbabilitySum = 0.0f;
//			for (int32 i = 0; i < Sequences.Num(); i++)
//			{
//				if (Sequences[i].Sequence == Exception)
//					continue;
//
//				ProbabilitySum += Sequences[i].Probability;
//			}
//
//			FRandomStream RandomStream = Math::Make ;
//			RandomStream.GenerateNewSeed();
//			float RandomNum = RandomStream.FRandRange(0.0f, ProbabilitySum);
//			float CurrentProbability = 0.0f;
//			for (int32 i = 0; i < Sequences.Num(); i++)
//			{
//				if (Sequences[i].Sequence == Exception)
//					continue;
//
//				CurrentProbability += Sequences[i].Probability;
//				if (RandomNum <= CurrentProbability)
//				{
//					return Sequences[i].Sequence;
//				}
//			}
//		}
//
//		return nullptr;
//	}
//
//};
