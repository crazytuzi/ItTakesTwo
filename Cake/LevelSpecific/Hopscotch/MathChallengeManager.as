import Cake.LevelSpecific.Hopscotch.MathChallengeActor;
import Cake.LevelSpecific.Hopscotch.HopscotchDoor;
import Vino.PlayerHealth.PlayerHealthStatics;

class AMathChallengeManager : AHazeActor
{
    UPROPERTY(RootComponent, DefaultComponent)
    UBillboardComponent Root;

    UPROPERTY(DefaultComponent, Attach = Root)
    UBillboardComponent TextLocation1;

    UPROPERTY(DefaultComponent, Attach = Root)
    UBillboardComponent TextLocation2;

    UPROPERTY(DefaultComponent, Attach = Root)
    UBillboardComponent TextLocation3;

    UPROPERTY(DefaultComponent, Attach = Root)
    UTextRenderComponent TextRender;
    default TextRender.WorldSize = 250.f;
    default TextRender.HorizontalAlignment = EHorizTextAligment::EHTA_Center;
    default TextRender.VerticalAlignment = EVerticalTextAligment::EVRTA_TextCenter;
    default TextRender.RelativeRotation = FRotator(90.f, 0.f, 0.f);
    default TextRender.bHiddenInGame = true;

    UPROPERTY(DefaultComponent, Attach = Root)
    UTextRenderComponent TimerTextRender;
    default TimerTextRender.WorldSize = 250.f;
    default TimerTextRender.HorizontalAlignment = EHorizTextAligment::EHTA_Center;
    default TimerTextRender.VerticalAlignment = EVerticalTextAligment::EVRTA_TextCenter;
    default TimerTextRender.RelativeRotation = FRotator(90.f, 0.f, 0.f);
    default TimerTextRender.bHiddenInGame = true;

    UPROPERTY()
    TArray<AMathChallengeActor> Challenge1;

    UPROPERTY()
    TArray<AMathChallengeActor> Challenge2;

    UPROPERTY()
    TArray<AMathChallengeActor> Challenge3;

    UPROPERTY()
    TArray<AHopscotchDoor> Challenge1Doors;

    UPROPERTY()
    TArray<AHopscotchDoor> Challenge2Doors;

    UPROPERTY()
    TArray<AHopscotchDoor> Challenge3Doors;

    UPROPERTY()
    TSubclassOf<UPlayerDeathEffect> DeathEffect;

    UPROPERTY()
    float Time = 5.f;
    
    int LeftPlayerAnswer;
    int RightPlayerAnswer;
    int Answer;
    int CurrentChallenge = 1;
    bool bChallengeActive;
    bool bShouldTickTimer;
    FString TextToShow;
    FString Operator = " + ";

    UFUNCTION(BlueprintOverride)
    void BeginPlay()
    {
		SetActorTickEnabled(false);
        TextRender.SetHiddenInGame(false);
        TimerTextRender.SetHiddenInGame(false);
        MoveTextRender(1);
        PickRandomAnswer(Answer);
    }

    UFUNCTION(BlueprintOverride)
    void Tick(float Delta)
    {
        CheckPlayerAnswers();
        
        TextToShow = FString("" + LeftPlayerAnswer + Operator + RightPlayerAnswer + "\n" + "=" + "\n" + Answer);
        
        TextRender.SetText(FText::FromString(TextToShow));

        if (bShouldTickTimer)
            ChangeTimer();
        
        if (CheckIfAnswerIsCorrect() &&bChallengeActive)
        {
            switch (CurrentChallenge)
            {   
                case 1:
                    for (AHopscotchDoor Doors : Challenge1Doors)
                    {
                        Doors.OpenDoor();
                    }
					for (AMathChallengeActor Challenge : Challenge1)
					{
						Challenge.SetActorTickEnabled(false);
					}
                break;
                
                case 2:
                    for (AHopscotchDoor Doors : Challenge2Doors)
                    {
                        Doors.OpenDoor();
                    }
					for (AMathChallengeActor Challenge : Challenge2)
					{
						Challenge.SetActorTickEnabled(false);
					}
                    Operator = " - ";
                break;
                
                case 3:
                    for (AHopscotchDoor Doors : Challenge3Doors)
                    {
                        Doors.OpenDoor();
						
                    }
					for (AMathChallengeActor Challenge : Challenge2)
					{
						Challenge.SetActorTickEnabled(false);
					}
						SetActorTickEnabled(false);
                break;
            }

            bChallengeActive = false;
            CurrentChallenge++;
            MoveTextRender(CurrentChallenge);
            PickRandomAnswer(Answer);
            SetTimerEnabled(0.f, false);
        } 
    }

    void MoveTextRender(int Challenge)
    {
        FVector NewTextLocation;

        switch (Challenge)
        {   
            case 1:
            NewTextLocation = TextLocation1.RelativeLocation;
            break;
            
            case 2:
            NewTextLocation = TextLocation2.RelativeLocation;
            break;
            
            case 3:
                NewTextLocation = TextLocation3.RelativeLocation;
            break;
        }
        TextRender.SetRelativeLocation(NewTextLocation);
        TimerTextRender.SetRelativeLocation(FVector(NewTextLocation + FVector(-500.f, 0.f, 0.f)));
    }

    void CheckPlayerAnswers()
    {
        switch (CurrentChallenge)
        {   
            case 1:
                LeftPlayerAnswer = Challenge1[0].CurrentBoxAnswer + 1;
                RightPlayerAnswer = Challenge1[1].CurrentBoxAnswer + 1;
            break;
            
            case 2:
                LeftPlayerAnswer = Challenge2[0].CurrentBoxAnswer + 1;
                RightPlayerAnswer = Challenge2[1].CurrentBoxAnswer + 1;
            break;
            
            case 3:
                LeftPlayerAnswer = Challenge3[0].CurrentBoxAnswer + 1;
                RightPlayerAnswer = Challenge3[1].CurrentBoxAnswer + 1;
            break;
        }
    }

    bool CheckIfAnswerIsCorrect()
    {
        if (CurrentChallenge < 3)
        {
            if (LeftPlayerAnswer + RightPlayerAnswer == Answer && LeftPlayerAnswer > 0 && RightPlayerAnswer > 0)
                return true;

            else
                return false;
        } else 
        {
            if (LeftPlayerAnswer - RightPlayerAnswer == Answer && LeftPlayerAnswer > 0 && RightPlayerAnswer > 0)
                return true;

            else
                return false;
        }
    }

    void PickRandomAnswer(int &RandAnsw)
    {
        switch (CurrentChallenge)
        {   
            case 1:
                RandAnsw = FMath::RandRange(2, 9);
            break;
            
            case 2:
                RandAnsw = FMath::RandRange(2, 9);
            break;
            
            case 3:
                RandAnsw = FMath::RandRange(1, 8);
            break;
        }
    }

    UFUNCTION()
    void SetPuzzleActive(bool bActive)
    {
        bChallengeActive = bActive;
    }

    UFUNCTION()
    void SetTimerEnabled(float NewTime, bool bEnabled)
    {
        Time = NewTime;
        bShouldTickTimer = bEnabled;
    }

   UFUNCTION(BlueprintEvent)
   void ChangeTimer()
    {
        if (Time > 0)
        {
            Time -= ActorDeltaSeconds; 
        }
        else
        {
            SetTimerEnabled(0.f, false);
            TriggerSpikes(false);
        }
            

        
        // CONVERTING A FLOAT TO TEXT IN ANGELSCRIPT MAKES THE GAME CRASH
        // DOING THE CONVERSION IN BLUEPRINT FOR NOW 
        
        // FText TextStuff;
        // TextStuff = Text::Conv_FloatToText(Time, ERoundingMode::HalfToEven, false, true, 1, 324, 2, 2);
        // TimerTextRender.SetText(FText::FromString("0" + TextStuff));
    }

    void TriggerSpikes(bool bShouldBeLowered)
    {
        for (AHazePlayerCharacter Player : Game::GetPlayers())
        {
            KillPlayer(Player, DeathEffect);
        }

        if (bShouldBeLowered)
        {
            SetPuzzleActive(false);
            SetPuzzleActive(true);
            PickRandomAnswer(Answer);
            SetTimerEnabled(10.f, true);
        }
        else 
        {
            System::SetTimer(this, n"HideSpikes", 2.f, false);
        }
        
        switch (CurrentChallenge)
            {   
                case 1:
                    for (AMathChallengeActor ChallengeActor : Challenge1)
                    {
                        ChallengeActor.MoveSpikes(bShouldBeLowered);
                        ChallengeActor.ResetAnswers();
                    }
                break;
                
                case 2:
                    for (AMathChallengeActor ChallengeActor : Challenge2)
                    {
                        ChallengeActor.MoveSpikes(bShouldBeLowered);
                        ChallengeActor.ResetAnswers();
                    }
                break;
                
                case 3:
                    for (AMathChallengeActor ChallengeActor : Challenge3)
                    {
                        ChallengeActor.MoveSpikes(bShouldBeLowered);
                        ChallengeActor.ResetAnswers();
                    }
                break;
            }
    }

    UFUNCTION()
    void HideSpikes()
    {
        TriggerSpikes(true);
    }
}