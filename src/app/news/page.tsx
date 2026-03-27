import {getNews, newsLocatorFromHref} from "@/serverRpcs";
import {Anchor, Container, Divider, Grid, GridCol, Group, Stack, Text, Title, TypographyStylesProvider} from "@mantine/core";
import classes from "@/app/global.module.css";
import Link from "next/link";
import newsClasses from "./news.module.css"
import {IconCalendar} from "@tabler/icons-react";
import type Parser from "rss-parser";

export const dynamic = "force-dynamic";

interface NewsCardProps {
  title: string,
  locator: string,
  date: Date,
  content: string
}

const NewsCard = ({title, locator, date, content}: NewsCardProps) => (
  <Stack>
    <Anchor component={Link} id={locator} href={"#" + locator}>
      <Title className={newsClasses.newsTitle} order={2}>
        {title}
      </Title>
    </Anchor>
    <TypographyStylesProvider className={newsClasses.newsCard}>
      <div dangerouslySetInnerHTML={{__html: content}}/>
    </TypographyStylesProvider>
    <Divider size={"sm"} label={
      <Group gap={"xxs"}>
        <IconCalendar size={16} stroke={1.5}/>
        以上新闻发布于 {new Intl.DateTimeFormat("zh-CN").format(date)}
      </Group>
    }/>
  </Stack>
)

export default async function NewsPage() {
  let news: Parser.Output<{}> | undefined;
  let error: unknown;
  try {
    news = await getNews();
  } catch (e) {
    error = e;
    console.error("Failed to fetch news feed for news page", e);
  }
  const errorMessage = error instanceof Error ? error.message : String(error);

  return (
    <Container className={classes.container} mt={"xl"}>
      <Grid justify={"center"}>
        <GridCol span={1} visibleFrom={"xs"} hiddenFrom={"md"}/>
        <GridCol span={{base: 12, xs: 10}}>
          <Stack gap={"xl"}>
            <Title order={1}>镜像站新闻</Title>
            {error ? (
              <Text c={"red"}>加载失败：{errorMessage}</Text>
            ) : (
              news?.items.map((item) => {
                const locator = newsLocatorFromHref(item.link!);
                return (
                  <NewsCard key={locator} title={item.title ?? "无题"} locator={locator}
                            date={new Date(item.isoDate ?? "")}
                            content={item.content ?? "N/A"}/>
                )
              })
            )}
          </Stack>
        </GridCol>
        <GridCol span={1} visibleFrom={"xs"} hiddenFrom={"md"}/>
      </Grid>
    </Container>
  )
}
