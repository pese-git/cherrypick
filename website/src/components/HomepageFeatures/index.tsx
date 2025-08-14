import type {ReactNode} from 'react';
import clsx from 'clsx';
import Heading from '@theme/Heading';
import styles from './styles.module.css';

type FeatureItem = {
  title: string;
  Svg: React.ComponentType<React.ComponentProps<'svg'>>;
  description: ReactNode;
};

const FeatureList: FeatureItem[] = [
  {
    title: 'Modular & Hierarchical',
    Svg: require('@site/static/img/undraw_docusaurus_mountain.svg').default,
    description: (
      <>
        CherryPick supports modular DI bindings and true hierarchical scopes. Build scalable apps by composing advanced dependency trees with clean separation of concerns.
      </>
    ),
  },
  {
    title: 'Sync & Async DI, Zero Boilerplate',
    Svg: require('@site/static/img/undraw_docusaurus_tree.svg').default,
    description: (
      <>
        Register synchronous or asynchronous providers, named and singleton dependencies, and enjoy null-safe, testable resolution. Annotation-based code generation removes all manual “wiring”.
      </>
    ),
  },
  {
    title: 'For Dart & Flutter',
    Svg: require('@site/static/img/undraw_docusaurus_react.svg').default,
    description: (
      <>
        Use CherryPick in backend, CLI, server or Flutter widget trees equally well. Deep Flutter integration for provider injection, async scope lifecycles, and easy testing.
      </>
    ),
  },
];

function Feature({title, Svg, description}: FeatureItem) {
  return (
    <div className={clsx('col col--4')}>
      <div className="text--center">
        <Svg className={styles.featureSvg} role="img" />
      </div>
      <div className="text--center padding-horiz--md">
        <Heading as="h3">{title}</Heading>
        <p>{description}</p>
      </div>
    </div>
  );
}

export default function HomepageFeatures(): ReactNode {
  return (
    <section className={styles.features}>
      <div className="container">
        <div className="row">
          {FeatureList.map((props, idx) => (
            <Feature key={idx} {...props} />
          ))}
        </div>
      </div>
    </section>
  );
}
