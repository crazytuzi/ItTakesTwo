
//enum ESwarmShapes
//{
//	None,
//	Sword,
//	Hammer,
//	Wall,
//	Shield,
//	HandSmash,
//	HandGrab,
//	Tornado,
//	Scissors,
//	HoneyComb,
//	Airplane,
//	MAX,
//};

// Support for multiple Skeletal mesh components on a single swarm
class UMultiSwarmAnimationSettingsDataAsset : USwarmAnimationSettingsBaseDataAsset
{
	UPROPERTY(BlueprintReadWrite, EditAnywhere, Category = "Animation")
	TArray<USwarmAnimationSettingsDataAsset> Assets;
};

class USwarmAnimationSettingsDataAsset : USwarmAnimationSettingsBaseDataAsset
{
 	UPROPERTY(meta = (ShowOnlyInnerProperties))
	FSwarmAnimationSettings Settings;
};

// needed because we now support multiple skeletons on 1 actor
UAnimSequence GetSequenceFromSwarmAnimDataAsset(USwarmAnimationSettingsBaseDataAsset InAnimAsset) 
{
	if (InAnimAsset == nullptr)
		return nullptr;

	const auto InAnimSettingsData_Single = Cast<USwarmAnimationSettingsDataAsset>(InAnimAsset);
	if(InAnimSettingsData_Single != nullptr)
	{
		return InAnimSettingsData_Single.Settings.OptionalSwarmAnimation.Sequence;
	}

	const auto InAnimSettingsData_Multi = Cast<UMultiSwarmAnimationSettingsDataAsset>(InAnimAsset);
	if(InAnimSettingsData_Multi != nullptr && InAnimSettingsData_Multi.Assets.Num() != 0)
	{
		return InAnimSettingsData_Multi.Assets[0].Settings.OptionalSwarmAnimation.Sequence;
	}

	return nullptr;
}

class USwarmAnimationSettingsBaseDataAsset : UDataAsset 
{
	// Just base class for the drop down menu
};

struct FStackableSwarmAnimationSettingsDataAssets 
{
	UPROPERTY(BlueprintReadWrite)
	USwarmAnimationSettingsDataAsset AnimSettingsDataAsset;

	UPROPERTY(BlueprintReadWrite)
	float InertiaBlendTime = 0.2f;

	UPROPERTY(BlueprintReadWrite)
	UObject Instigator = nullptr;

	FStackableSwarmAnimationSettingsDataAssets(
		USwarmAnimationSettingsDataAsset InDataAsset,
		UObject InObject
	)
	{
		AnimSettingsDataAsset = InDataAsset;
		Instigator = InObject;
	}

	FStackableSwarmAnimationSettingsDataAssets(
		USwarmAnimationSettingsDataAsset InDataAsset,
		UObject InObject,
		float InInertiaBlendTime
	)
	{
		AnimSettingsDataAsset = InDataAsset;
		Instigator = InObject;
		InertiaBlendTime = InInertiaBlendTime;
	}

	bool opEquals(const FStackableSwarmAnimationSettingsDataAssets& Other) const
	{
		return Instigator == Other.Instigator;
	}

	bool opEquals(FStackableSwarmAnimationSettingsDataAssets& Other) const
	{
		return Instigator == Other.Instigator;
	}

};

